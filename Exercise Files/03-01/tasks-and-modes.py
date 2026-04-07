### Ultralytics YOLO Tasks and Modes

from ultralytics import YOLO

# Load a model
model = YOLO("yolo11n-seg.pt")  # load an official model
#model = YOLO("yolo11n-seg.torchscript")
# model = YOLO("path/to/best.pt")  # load a custom model

# Predict with the model
results = model.predict(
    source="video.mov", show=True
    )

# Track with the model
# results = model.track(
#     source="video.mov", show=True
#     )

# Export with the model
# results = model.export(
#     format="torchscript",  # export format
#     )


# Access the results
# for result in results:
#     xywh = result.boxes.xywh  # center-x, center-y, width, height
#     xywhn = result.boxes.xywhn  # normalized
#     xyxy = result.boxes.xyxy  # top-left-x, top-left-y, bottom-right-x, bottom-right-y
#     xyxyn = result.boxes.xyxyn  # normalized
#     names = [result.names[cls.item()] for cls in result.boxes.cls.int()]  # class name of each box
#     confs = result.boxes.conf  # confidence score of each box
