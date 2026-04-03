import cv2
from ultralytics import solutions

cap = cv2.VideoCapture("video.mov")
w, h, fps = (
    int(cap.get(x))
    for x in (cv2.CAP_PROP_FRAME_WIDTH,
              cv2.CAP_PROP_FRAME_HEIGHT,
              cv2.CAP_PROP_FPS))
video_writer = (
    cv2.VideoWriter(
        "result.avi",
        cv2.VideoWriter_fourcc(*"mp4v"),
        fps, (1280, 720)))


# Analytics Module Initialization
solution = solutions.Analytics(
    model="new-model.pt",
    analytics_type="pie",
    device="cpu",
    show=True,
)

frame_count = 0
# Process video
while cap.isOpened():
    success, im0 = cap.read()
    if not success:
        break
    frame_count += 1
    results = solution(im0, frame_count)
    video_writer.write(results.plot_im)
cap.release()
video_writer.release()
cv2.destroyAllWindows()  # destroy windows

# from ultralytics import YOLO
#
# model = YOLO("new-model.pt")
#
# model.predict(source="video.mov",
#               show=True)