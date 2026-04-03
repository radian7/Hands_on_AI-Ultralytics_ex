from ultralytics import YOLO

model = YOLO("yolo11n.pt")

# model.predict(source="video.mov",
#               show=True,
#               line_width=2,)

if __name__ == '__main__':
    model.train(
        data="data.yaml",
        batch=16,
        workers=1,
        epochs=100,
    )
    