# from ultralytics import YOLO
#
# model = YOLO("yolo11.pt")

# from ultralytics import SAM
#
# # Load a model
# model = SAM("sam2.1_b.pt")
#
# # Run inference
# model.predict(
#     source="image.png", save=True)

from ultralytics import FastSAM

# Create a FastSAM model
model = FastSAM("FastSAM-s.pt")  # or FastSAM-x.pt

# Run inference on an image
everything_results = model.predict(
    source="image.png",
    device=0,
    retina_masks=True,
    imgsz=1024,
    conf=0.4,
    iou=0.9,
save=True,)
