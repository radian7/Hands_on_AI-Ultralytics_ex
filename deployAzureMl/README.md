# ONNX Inference — .NET 9 + Azure ML + OpenTofu

## Architektura

```
model.onnx
    │
    ├─► [1] Upload → Azure ML Datastore (workspaceblobstore)
    │
    ├─► [2] Rejestracja → Azure ML Model Registry
    │
    ├─► [3] ACR → obraz Docker z .NET 9 + ONNX Runtime
    │
    └─► [4] Azure ML Online Endpoint
             └── Deployment (BYOC)
                  ├── runtime: .NET 9 (NIE Python)
                  ├── model: zamontowany pod /mnt/models/model.onnx
                  └── scoring: POST /api/inference/predict:8080
```

## Wymagania wstępne

```bash
# Narzędzia
az --version          # Azure CLI >= 2.60
tofu --version        # OpenTofu >= 1.7
az extension add -n ml --yes   # Azure ML extension

# Zaloguj się
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

## Krok 1 — Przygotuj zmienne

```bash
cp terraform.tfvars.example terraform.tfvars
# Uzupełnij terraform.tfvars swoimi wartościami
```

## Krok 2 — Zbuduj obraz .NET i wypchnij do ACR

```bash
# Najpierw tofu apply tylko dla ACR (żeby mieć login server)
tofu init
tofu apply -target=module.acr

# Zaloguj się do ACR
ACR_SERVER=$(tofu output -raw acr_login_server)
az acr login --name <ACR_NAME>

# Zbuduj i wypchnij obraz
docker build -t ${ACR_SERVER}/onnx-dotnet-api:1.0.0 ../dotnet-api/
docker push ${ACR_SERVER}/onnx-dotnet-api:1.0.0

# Zaktualizuj container_image w terraform.tfvars:
# container_image = "<acr_server>/onnx-dotnet-api:1.0.0"
```

## Krok 3 — Upload model.onnx do datastore

```bash
az ml datastore upload \
  --name workspaceblobstore \
  --src-dir <katalog_z_modelem_onnx> \
  --target-path models/onnx-dotnet-model/1/ \
  --workspace-name Workspace1 \
  --resource-group <RESOURCE_GROUP>
```

## Krok 4 — Deploy całości przez OpenTofu

```bash
tofu plan
tofu apply
```

## Krok 5 — Test endpointu

```bash
# Pobierz URL i klucz
ENDPOINT_URL=$(tofu output -raw endpoint_url)
API_KEY=$(az ml online-endpoint get-credentials \
  -n onnx-dotnet-endpoint \
  -g <RESOURCE_GROUP> \
  -w Workspace1 \
  --query primaryKey -o tsv)

# Wywołaj endpoint
curl -X POST "${ENDPOINT_URL}" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"input": [[[0.5, 0.5, 0.5]]], "shape": [1, 3, 224, 224]}'
```

## Struktura projektu

```
.
├── infra/
│   ├── providers.tf              # OpenTofu providers (azurerm + azapi)
│   ├── variables.tf              # Wszystkie zmienne
│   ├── main.tf                   # Orkiestracja modułów
│   ├── outputs.tf                # URL endpointu, ID zasobów
│   ├── terraform.tfvars.example  # Przykładowe wartości
│   ├── deploy.yml                # GitHub Actions CI/CD
│   └── modules/
│       ├── acr/
│       │   └── main.tf           # Azure Container Registry
│       ├── ml_model/
│       │   └── main.tf           # Rejestracja modelu ONNX
│       └── ml_endpoint/
│           └── main.tf           # Endpoint + BYOC deployment
└── dotnet-api/
    └── Dockerfile                # .NET 9 multi-stage build
```

## Kluczowe decyzje techniczne

| Element | Wybór | Dlaczego |
|---|---|---|
| Runtime | .NET 9 | Brak GIL, niższe zużycie RAM, szybszy cold start |
| Inference | ONNX Runtime | Ten sam silnik co w Pythonie, pełne wsparcie C# |
| Deployment | BYOC (własny kontener) | Pełna kontrola, brak wymogu score.py |
| IaC | OpenTofu + azapi | azapi daje dostęp do najnowszych API Azure ML |
| Auth | User-Assigned Managed Identity | Bez secrets, pull ACR + dostęp do modelu |

## Zmienne GitHub Actions (Settings → Secrets and Variables)

**Variables (vars.*):**
- `SUBSCRIPTION_ID`
- `TENANT_ID`
- `CLIENT_ID`
- `RESOURCE_GROUP`
- `WORKSPACE_NAME`
- `ACR_NAME`
- `MODEL_NAME`

**Secrets:**
- `AZURE_CREDENTIALS` — JSON z `az ad sp create-for-rbac`
- `CLIENT_SECRET` — secret Service Principal
