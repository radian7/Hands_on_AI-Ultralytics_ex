from ultralytics import YOLO

model = YOLO("best-detect.pt")

if __name__ == '__main__':
    model.benchmark(
        data="../03-02/data.yaml",
        # format="onnx"
    )
    print("Model Benchmark...")
