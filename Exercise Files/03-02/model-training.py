from ultralytics import YOLO

# model = YOLO("yolo11n.pt")


# # train
# if __name__ == '__main__':
#     model.train(
#         data="data.yaml",
#         batch=16,
#         workers=1,
#         epochs=100,
#     )
# device=0 aby użyć GPU RTX 3060 (wymaga pyTorch with CUDA), device=-1 aby użyć CPU 


model = YOLO("runs\\detect\\train\\weights\\best.pt")

model.predict(source="video.mov",
              show=True,
              line_width=2,)
