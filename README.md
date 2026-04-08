
## Deploy modelu na Azure ML (OpenTofu)

Pliki konfiguracyjne znajdują się w `deployAzureMl/`.

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
   cd deployAzureMl
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
deployAzureMl/
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


Flow przetwarzania i deploymentu:
Cały proces odbywa się automatycznie po stronie Azure ML i składa się z kilku etapów:

1. Rejestracja modelu w Azure ML Registry
Terraform rejestruje plik .torchscript jako artefakt modelu:

Azure ML przesyła plik do wewnętrznego Azure Blob Storage połączonego z workspace'em (kontener azureml-blobstore-...).

2. Deployment — budowanie obrazu kontenera
Kiedy Azure ML przetwarza deployment.yaml.tftpl:

Azure ML buduje obraz Docker, w którym:

bazowy obraz to mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference
kod score/ jest kopiowany do obrazu
3. Montowanie modelu przy starcie kontenera
Gdy kontener startuje na endpoincie, Azure ML automatycznie:

Pobiera artefakty modelu z Blob Storage
Montuje je (lub kopiuje) do ścieżki wewnątrz kontenera
Ustawia zmienną środowiskową:
Struktura katalogów w kontenerze wygląda wtedy tak:

4. Wywołanie init() w score.py
init() odczytuje AZUREML_MODEL_DIR i przeszukuje tę ścieżkę:

Podsumowanie przepływu
Kluczowa rzecz: score.py nie pobiera modelu samodzielnie — dostaje gotową ścieżkę lokalną przez zmienną środowiskową. Całą logistyką (pobieranie z Blob, montowanie, ustawianie env var) zajmuje się platforma Azure ML.



# Deploy API:
Workflow przy kolejnych zmianach conda.yaml:

Zwiększ env_version w terraform.tfvars (np. "5" → "6")
Uruchom .\redeploy.ps1



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



# 03-02 trenowanie modelu
cd .\03-04
po trenowaniu segmentacji
oglądamy MaskPR_vurve.png - Precision-recall - krzywa precyzji jest ważna dla trenowania segmentacji
jesli ma powyżej 85% to jest to dobry wynik, nawet 80% jest akceptowalna


