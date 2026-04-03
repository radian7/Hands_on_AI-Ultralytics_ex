from ultralytics import YOLO

model = YOLO("yolo11n-pose.pt")

model.export(
    format="torchscript",
    # simplify=True,
    batch=2,
    imgsz=416,
)

