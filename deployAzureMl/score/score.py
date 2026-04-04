import base64
import io
import json
import os
import logging

import torch
import numpy as np
from PIL import Image
from torchvision.ops import nms

logger = logging.getLogger(__name__)

IMG_SIZE = 640


def init():
    global model

    model_dir = os.getenv("AZUREML_MODEL_DIR")

    # Find TorchScript model file in the model directory tree
    model_path = None
    for root, _dirs, files in os.walk(model_dir):
        for fname in files:
            if fname.endswith((".torchscript", ".pt")):
                model_path = os.path.join(root, fname)
                break
        if model_path:
            break

    if not model_path:
        raise FileNotFoundError(
            f"No TorchScript model (.torchscript / .pt) found in {model_dir}"
        )

    logger.info("Loading TorchScript model from %s", model_path)
    model = torch.jit.load(model_path, map_location="cpu")
    model.eval()
    logger.info("Model loaded successfully")


# Progi zgodne z domyślnymi wartościami Ultralytics YOLO.predict()
CONF_THRESHOLD = 0.25
IOU_THRESHOLD = 0.45


def _decode_image(b64_string: str) -> torch.Tensor:
    """Decode base64 image to a [1, 3, IMG_SIZE, IMG_SIZE] float32 tensor."""
    raw = base64.b64decode(b64_string)
    img = Image.open(io.BytesIO(raw)).convert("RGB")
    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img, dtype=np.float32) / 255.0  # [H, W, C] 0-1
    arr = arr.transpose(2, 0, 1)  # [C, H, W]
    return torch.from_numpy(arr).unsqueeze(0)  # [1, C, H, W]


def _apply_nms(raw_output: torch.Tensor) -> list:
    """Zastosuj NMS na surowym wyjściu modelu i zwróć listę detekcji.

    Wejście:  tensor [1, 84, 8400]  (4 coords + 80 klas COCO)
    Wyjście:  lista słowników [{'box': [x1,y1,x2,y2], 'score': float, 'class_id': int}, ...]
    """
    # Transponuj: [1, 84, 8400] → [8400, 84]
    preds = raw_output[0].T

    # Rozdziel współrzędne (cx,cy,w,h) i prawdopodobieństwa klas
    boxes_cxcywh = preds[:, :4]
    class_scores = preds[:, 4:]

    # Dla każdej propozycji weź klasę z najwyższym prawdopodobieństwem
    scores, class_ids = class_scores.max(dim=1)

    # Odfiltruj propozycje poniżej progu pewności
    mask = scores > CONF_THRESHOLD
    boxes_cxcywh = boxes_cxcywh[mask]
    scores = scores[mask]
    class_ids = class_ids[mask]

    if scores.numel() == 0:
        return []

    # Konwersja cx,cy,w,h → x1,y1,x2,y2 (format wymagany przez torchvision nms)
    boxes_xyxy = torch.stack([
        boxes_cxcywh[:, 0] - boxes_cxcywh[:, 2] / 2,  # x1
        boxes_cxcywh[:, 1] - boxes_cxcywh[:, 3] / 2,  # y1
        boxes_cxcywh[:, 0] + boxes_cxcywh[:, 2] / 2,  # x2
        boxes_cxcywh[:, 1] + boxes_cxcywh[:, 3] / 2,  # y2
    ], dim=1)

    # NMS — usuń nakładające się boxy dla tego samego obiektu
    keep = nms(boxes_xyxy, scores, IOU_THRESHOLD)

    detections = []
    for idx in keep:
        detections.append({
            "box": boxes_xyxy[idx].tolist(),   # [x1, y1, x2, y2] w pikselach 640x640
            "score": round(scores[idx].item(), 4),
            "class_id": int(class_ids[idx].item()),
        })
    return detections


def run(raw_data):
    try:
        data = json.loads(raw_data)
        input_tensor = _decode_image(data["image_base64"])

        with torch.no_grad():
            result = model(input_tensor)

        if isinstance(result, torch.Tensor):
            detections = _apply_nms(result)
            return {"detections": detections, "count": len(detections)}
        return {"output": str(result)}
    except Exception as e:
        logger.error("Inference error: %s", e)
        return {"error": str(e)}
