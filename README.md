# Hands_on_AI-Ultralytics_ex

# 01-02
`pip install -r '.\Exercise Files\requirements.txt'`

`cd '.\Exercise Files\01-02'`

`uv run .\opencv_operations.py`


# 02-01 prygotowanie danych uczących za pomocą label-studio

`pip install label-studio`

# po instlacji uruchom:

`label-studio start`

otworzy się w domyślnej przeglądarce

Ręcznie mozna zaznaczać obiekty na zdjęciach i  dodawać do nich labelki 

potem ekspotuje sie to do pliku zip w formacie yolo

uzywa sie tego do trenowania


# 02-02
rozpoakowanie danych do uczenia modelu
cd 02-02

`uv run split-data.py`

# 03-01 eksportowanie modelu
`cd 03-01`

`uv run tasks-and-modes.py`

# 03-02 trenowanie modelu
cd .\03-02
Warto zainstalować pyTorch with Cuda, aby użyć GPU
użyj device=0 w model.train()

`uv run  .\model-training.py`

Model poprawia się epoka po epoce

Po zkaończeniu trenowania mozna obejrzec np. plik PR_curve.png
jest to krzywa precyzji i kopletność powinno być powyżej 89%



