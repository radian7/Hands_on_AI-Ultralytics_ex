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


# Solution Module Initialization
solution = solutions.ObjectBlurrer(
    model="yolo11n.pt",
    show=True,
    line_width=3,
#    blur_ratio=0.6,
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
