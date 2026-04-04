import base64
import io
import json
import os
import logging

import torch
import numpy as np
from PIL import Image

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


def _decode_image(b64_string: str) -> torch.Tensor:
    """Decode base64 image to a [1, 3, IMG_SIZE, IMG_SIZE] float32 tensor."""
    raw = base64.b64decode(b64_string)
    img = Image.open(io.BytesIO(raw)).convert("RGB")
    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img, dtype=np.float32) / 255.0  # [H, W, C] 0-1
    arr = arr.transpose(2, 0, 1)  # [C, H, W]
    return torch.from_numpy(arr).unsqueeze(0)  # [1, C, H, W]


def run(raw_data):
    try:
        data = json.loads(raw_data)
        input_tensor = _decode_image(data["image_base64"])

        with torch.no_grad():
            result = model(input_tensor)

        if isinstance(result, torch.Tensor):
            return {"output": result.tolist()}
        return {"output": str(result)}
    except Exception as e:
        logger.error("Inference error: %s", e)
        return {"error": str(e)}
