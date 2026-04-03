import cv2
from ultralytics import solutions

cap = cv2.VideoCapture("video1.mp4")
w, h, fps = (
    int(cap.get(x))
    for x in (cv2.CAP_PROP_FRAME_WIDTH,
              cv2.CAP_PROP_FRAME_HEIGHT,
              cv2.CAP_PROP_FPS))
video_writer = (
    cv2.VideoWriter(
        "result.avi",
        cv2.VideoWriter_fourcc(*"mp4v"),
        fps, (w, h)))


# ObjectCounting Module Initialization
solution = solutions.ObjectCounter(
    model="yolo11n.pt",
    classes=[39],
    show_in=True, show_out=True,
    show=True,
    region=[(640, 0), (640, 720)],
    line_width=4,
)


# Process video
while cap.isOpened():
    success, im0 = cap.read()
    if not success:
        break
    results = solution(im0)
    video_writer.write(results.plot_im)
cap.release()
video_writer.release()
cv2.destroyAllWindows()  # destroy windows
