### Ultralytics YOLO Usage

from ultralytics import YOLO

# Load the model
# https://docs.ultralytics.com/models
model = YOLO("yolo11n-pose.pt")
#..................................

# Use different modes
# https://docs.ultralytics.com/modes
results = model.predict(source="image.png",
                        save=True)
#..................................

# Extract the results
# https://docs.ultralytics.com/modes/predict/#working-with-results
for result in results:
    print(result.keypoints)
#..................................
