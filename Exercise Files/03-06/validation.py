from ultralytics import YOLO

model = YOLO("best-segment.pt")

if __name__ == '__main__':
    metrics = model.val(
        data="../03-04/data.yaml"
    )
    print("Model Validation...")
    # metrics extraction
    print(metrics.box.map)
    print(metrics.box.ap)
    print(metrics.box.mr)
    print(metrics.box.map50)
