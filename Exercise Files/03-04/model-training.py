from ultralytics import YOLO

model = YOLO("runs/segment/train/weights/best.pt")

model.predict(source="../03-02/video.mov",
              show=True,
              line_width=2,
              show_boxes=False)

# if __name__ == '__main__':
#     model.train(
#         data="data.yaml",
#         batch=16,
#         workers=1,
#         epochs=100,
#     )