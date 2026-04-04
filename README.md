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

## Eksport modelu do TorchScript

```bash
cd 03-02
uv run .\export-model.py
```

Skrypt załaduje wytrenowany model (`runs\detect\train\weights\best.pt`) i wyeksportuje go do formatu TorchScript.

## Deploy modelu na Azure ML (OpenTofu)

Pliki konfiguracyjne znajdują się w `Exercise Files/03-02/deploy/`.

### Wymagania
- [OpenTofu](https://opentofu.org/) >= 1.6
- Azure CLI (`az`) z rozszerzeniem `ml` (`az extension add -n ml`)
- Istniejący Azure ML Workspace

### Kroki

1. **Zaloguj się do Azure:**
   ```bash
   az login
   ```

2. **Skopiuj i uzupełnij konfigurację:**
   ```bash
   cd "Exercise Files/03-02/deploy"
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edytuj `terraform.tfvars` — ustaw `subscription_id`, `resource_group_name` i `model_local_path` (ścieżka do pliku `.torchscript`).

3. **Zainicjalizuj i wykonaj deploy:**
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

### Co zostanie utworzone
| Zasób | Opis |
|---|---|
| Model w Azure ML | Rejestracja pliku TorchScript jako custom model |
| Managed Online Endpoint | Endpoint z auth_mode=Key do real-time inference |
| Deployment | Instancja Standard_DS3_v2 z curated PyTorch environment |

### Struktura plików deploy
```
deploy/
├── providers.tf                  # azurerm + azapi providers
├── variables.tf                  # zmienne (model_local_path, endpoint_name, ...)
├── main.tf                       # workspace ref + model + endpoint + deployment
├── outputs.tf                    # scoring URI
├── terraform.tfvars.example      # przykładowa konfiguracja
├── templates/
│   └── deployment.yaml.tftpl     # szablon deployment YAML
└── score/
    └── score.py                  # scoring script (init/run)
```

### Usunięcie zasobów
```bash
tofu destroy
```

