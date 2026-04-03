# Hands_on_AI-Ultralytics_ex

# 01-02
pip install -r '.\Exercise Files\requirements.txt'

cd '.\Exercise Files\01-02'
uv run .\opencv_operations.py


# 02-01
pip install label-studio
# po instlacji uruchom:
label-studio start

otworzy się w domyślnej przeglądarce

Ręcznie mozna zaznaczać obiekty na zdjęciach i  dodawać do nich labelki 

potem ekspotuje sie to do pliku zip w formacie yolo

uzywa sie tego do trenowania


# 02-02
rozpoakowanie danych do uczenia modelu
cd 02-02
uv run split-data.py

# 03-01
cd 03-01
uv run tasks-and-modes.py


