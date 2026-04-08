from ultralytics import YOLO


model = YOLO("runs\\detect\\train5\\weights\\best.pt")

model.predict(source="video.mov",
              show=True,
              line_width=2,)
