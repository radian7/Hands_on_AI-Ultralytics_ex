### Ultralytics YOLO Tasks and Modes

from ultralytics import YOLO

# Load a model
#model = YOLO("yolo11n-seg.pt")  # load an official model
#model = YOLO("yolo11n-seg.torchscript")
model = YOLO("runs\\detect\\train5\\weights\\best.pt")  # load a custom model


#Export with the model
results = model.export(
    format="TorchScript",  # export format, TorchScript lub onnx
    )

