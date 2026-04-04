"""
Generuje plik sample_input.json z obrazu zakodowanego w base64,
kompatybilny ze scoring scriptem deployowanego modelu YOLO TorchScript.

Uzycie:
    python generate_payload.py sciezka/do/obrazu.jpg
    python generate_payload.py sciezka/do/obrazu.jpg -o moj_payload.json
"""

import argparse
import base64
import json
import os


def main():
    parser = argparse.ArgumentParser(description="Generuj JSON payload (base64) dla YOLO endpoint")
    parser.add_argument("image", help="Sciezka do pliku obrazu (jpg/png)")
    parser.add_argument("-o", "--output", default="sample_input.json", help="Sciezka wyjsciowa JSON")
    args = parser.parse_args()

    with open(args.image, "rb") as f:
        img_bytes = f.read()

    b64 = base64.b64encode(img_bytes).decode()

    with open(args.output, "w") as f:
        json.dump({"image_base64": b64}, f)

    img_kb = round(len(img_bytes) / 1024, 1)
    out_kb = round(os.path.getsize(args.output) / 1024, 1)
    print(f"Obraz: {args.image} ({img_kb} KB)")
    print(f"Zapisano: {args.output} ({out_kb} KB)")


if __name__ == "__main__":
    main()
