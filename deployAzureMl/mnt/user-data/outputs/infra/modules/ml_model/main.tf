variable "workspace_id"     { type = string }
variable "model_name"       { type = string }
variable "model_version"    { type = string }
variable "model_local_path" { type = string }
variable "location"         { type = string }
variable "tags"             { type = map(string) }

# ─────────────────────────────────────────────────────────────
# Krok 1: Upload pliku model.onnx do domyślnego datastore
#         za pomocą AzAPI resource action
# ─────────────────────────────────────────────────────────────
#
# Azure ML automatycznie tworzy datastore "workspaceblobstore"
# w każdym workspace. Model rejestrujemy wskazując ścieżkę
# w tym datastorze po wcześniejszym uploadzie przez CLI/script.
#
# Upload pliku model.onnx wykonaj PRZED tofu apply:
#
#   az ml datastore upload \
#     --name workspaceblobstore \
#     --src-dir <katalog_z_modelem> \
#     --target-path models/onnx-dotnet-model/1/ \
#     --workspace-name Workspace1 \
#     --resource-group <RG>
#
# ─────────────────────────────────────────────────────────────

locals {
  # Ścieżka w datastorze — musi pasować do miejsca uploadu powyżej
  model_datastore_uri = "azureml://datastores/workspaceblobstore/paths/models/${var.model_name}/${var.model_version}/model.onnx"
}

# Rejestracja modelu (kontener nazwy)
resource "azapi_resource" "ml_model" {
  type      = "Microsoft.MachineLearningServices/workspaces/models@2024-10-01"
  name      = var.model_name
  parent_id = var.workspace_id

  body = {
    properties = {
      description = "Model ONNX serwowany przez .NET runtime (BYOC)"
      tags        = var.tags
    }
  }

  response_export_values = ["*"]
}

# Rejestracja konkretnej wersji modelu
resource "azapi_resource" "ml_model_version" {
  type      = "Microsoft.MachineLearningServices/workspaces/models/versions@2024-10-01"
  name      = var.model_version
  parent_id = azapi_resource.ml_model.id

  body = {
    properties = {
      # Wskazuje plik w datastorze (po uploadzie przez CLI)
      modelUri    = local.model_datastore_uri
      description = "ONNX v${var.model_version} — runtime: .NET + Microsoft.ML.OnnxRuntime"

      flavors = {
        # Informacja o frameworku — czysto metadanowa, nie wpływa na runtime
        onnx = {
          data = {
            "onnx_version" = "1.16"
          }
        }
      }

      properties = {
        "runtime"   = "dotnet"
        "framework" = "onnx"
      }

      tags = var.tags
    }
  }

  depends_on = [azapi_resource.ml_model]

  response_export_values = ["*"]
}

output "model_id" {
  value = azapi_resource.ml_model.id
}

output "model_version_id" {
  # Format: azureml:/<name>:<version> — używany w deployment
  value = "${azapi_resource.ml_model.id}/versions/${var.model_version}"
}
