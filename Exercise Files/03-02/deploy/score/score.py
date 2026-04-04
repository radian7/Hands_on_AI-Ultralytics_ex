import json
import os
import logging

import torch
import numpy as np

logger = logging.getLogger(__name__)


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


def run(raw_data):
    try:
        data = json.loads(raw_data)
        input_array = np.array(data["input"], dtype=np.float32)
        input_tensor = torch.from_numpy(input_array)

        with torch.no_grad():
            result = model(input_tensor)

        if isinstance(result, torch.Tensor):
            return {"output": result.tolist()}
        return {"output": str(result)}
    except Exception as e:
        logger.error("Inference error: %s", e)
        return {"error": str(e)}
