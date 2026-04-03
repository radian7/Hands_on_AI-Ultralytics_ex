from ultralytics import YOLO

model = YOLO("yolo11n.pt")

model.track(
    persist=True,
    source="video.mov",
    conf=0.6,  # 60% confidence score
    line_width=4,
    device=0,
    # max_det=2,
    show=True,
    save=True,
    tracker="bytetrack.yaml"
)
