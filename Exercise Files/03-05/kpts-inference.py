from ultralytics import YOLO

model = YOLO("yolo11n-pose.pt")

model.predict(
    source="video.mov",
    line_width=7,
    conf=0.5,
    show=True,
)
