variable "workspace_id"    { type = string }
variable "location"        { type = string }
variable "endpoint_name"   { type = string }
variable "deployment_name" { type = string }
variable "model_id"        { type = string }
variable "container_image" { type = string }
variable "acr_id"          { type = string }
variable "instance_type"   { type = string }
variable "instance_count"  { type = number }
variable "tags"            { type = map(string) }

# ─────────────────────────────────────────────────────────────
# User-Assigned Managed Identity
# Endpoint i deployment używają jej do:
#   - pullowania obrazu z ACR
#   - dostępu do datastora (model.onnx)
# ─────────────────────────────────────────────────────────────

resource "azapi_resource" "endpoint_identity" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name      = "id-${var.endpoint_name}"
  parent_id = regex("(.+)/providers/Microsoft.MachineLearningServices/.+", var.workspace_id)[0]
  location  = var.location

  body = {}

  response_export_values = ["properties.principalId", "properties.clientId"]
}

locals {
  identity_id           = azapi_resource.endpoint_identity.id
  identity_principal_id = azapi_resource.endpoint_identity.output.properties.principalId
  # Resource Group ID wyciągnięte z workspace_id
  resource_group_id     = regex("(.+)/providers/Microsoft.MachineLearningServices/.+", var.workspace_id)[0]
}

# Uprawnienie: Managed Identity może pullować obrazy z ACR
resource "azapi_resource" "acr_pull_assignment" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("dns", "${var.acr_id}/AcrPull/${local.identity_id}")
  parent_id = var.acr_id

  body = {
    properties = {
      # AcrPull role definition ID (globalny w Azure)
      roleDefinitionId = "${local.resource_group_id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
      principalId      = local.identity_principal_id
      principalType    = "ServicePrincipal"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# Environment — BYOC (Bring Your Own Container)
# Wskazuje na obraz .NET z ACR, NIE na curated Python env
# inference_config definiuje routing HTTP do kontenera
# ─────────────────────────────────────────────────────────────

resource "azapi_resource" "ml_environment" {
  type      = "Microsoft.MachineLearningServices/workspaces/environments@2024-10-01"
  name      = "dotnet-onnx-env"
  parent_id = var.workspace_id

  body = {
    properties = {
      description = "BYOC środowisko — .NET 9 + ONNX Runtime, bez Pythona"
      tags        = var.tags
    }
  }

  response_export_values = ["*"]
}

resource "azapi_resource" "ml_environment_version" {
  type      = "Microsoft.MachineLearningServices/workspaces/environments/versions@2024-10-01"
  name      = "1"
  parent_id = azapi_resource.ml_environment.id

  body = {
    properties = {
      # Własny obraz Docker (.NET) zamiast curated Python
      image = var.container_image

      # inference_config — kluczowe dla BYOC:
      # definiuje ścieżki probe i scoring, które Azure ML
      # będzie wywoływać na kontenerze
      inferenceConfig = {
        livenessRoute = {
          path = "/health"
          port = 8080
        }
        readinessRoute = {
          path = "/health"
          port = 8080
        }
        scoringRoute = {
          path = "/api/inference/predict"
          port = 8080
        }
      }

      osType      = "Linux"
      description = ".NET 9 Web API z Microsoft.ML.OnnxRuntime"
      tags        = var.tags
    }
  }

  depends_on = [azapi_resource.ml_environment]

  response_export_values = ["*"]
}

# ─────────────────────────────────────────────────────────────
# Online Endpoint
# ─────────────────────────────────────────────────────────────

resource "azapi_resource" "online_endpoint" {
  type      = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-10-01"
  name      = var.endpoint_name
  parent_id = var.workspace_id
  location  = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [local.identity_id]
  }

  body = {
    properties = {
      authMode            = "Key"        # Key lub AMLToken lub AADToken
      description         = "ONNX inference — .NET 9 runtime, BYOC"
      publicNetworkAccess = "Enabled"
      traffic             = {}          # traffic ustawiamy po deployment
    }
    tags = var.tags
  }

  response_export_values = ["properties.scoringUri", "properties.swaggerUri"]

  depends_on = [azapi_resource.acr_pull_assignment]
}

# ─────────────────────────────────────────────────────────────
# Online Deployment — właściwy deployment z .NET kontenerem
# ─────────────────────────────────────────────────────────────

resource "azapi_resource" "online_deployment" {
  type      = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints/deployments@2024-10-01"
  name      = var.deployment_name
  parent_id = azapi_resource.online_endpoint.id
  location  = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [local.identity_id]
  }

  body = {
    kind = "Managed"

    properties = {
      # Wskazanie zarejestrowanego modelu ONNX
      # Azure ML zamontuje plik pod MODEL_BASE_PATH w kontenerze
      model          = var.model_id
      modelMountPath = "/mnt/models"   # ścieżka montowania w kontenerze

      # Środowisko BYOC — .NET zamiast Python
      environmentId = "${azapi_resource.ml_environment.id}/versions/1"

      # Zmienne środowiskowe przekazywane do kontenera .NET
      environmentVariables = {
        # Ścieżka do model.onnx — musi pasować do model_mount_path + nazwy pliku
        "Onnx__ModelPath"        = "/mnt/models/model.onnx"
        "ASPNETCORE_ENVIRONMENT" = "Production"
        "ASPNETCORE_URLS"        = "http://+:8080"
        # Opcjonalne: dla GPU odkomentuj
        # "OnnxRuntime__Provider" = "CUDA"
      }

      instanceType  = var.instance_type
      instanceCount = var.instance_count

      # Proby — Azure ML sprawdza /health na porcie 8080
      livenessProbe = {
        initialDelay    = "PT30S"   # 30 sekund po starcie (ISO 8601)
        period          = "PT10S"   # co 10 sekund
        timeout         = "PT5S"
        successThreshold = 1
        failureThreshold = 3
      }

      readinessProbe = {
        initialDelay    = "PT10S"
        period          = "PT10S"
        timeout         = "PT5S"
        successThreshold = 1
        failureThreshold = 3
      }

      # App Insights — metryki i logi
      appInsightsEnabled = true

      description = "Deployment .NET 9 + ONNX Runtime (BYOC)"
    }

    tags = var.tags
  }

  # Deployment trwa długo — zwiększ timeout
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }

  depends_on = [
    azapi_resource.online_endpoint,
    azapi_resource.ml_environment_version,
  ]

  response_export_values = ["*"]
}

# ─────────────────────────────────────────────────────────────
# Ustaw 100% ruchu na deployment po jego gotowości
# ─────────────────────────────────────────────────────────────

resource "azapi_update_resource" "endpoint_traffic" {
  type      = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-10-01"
  resource_id = azapi_resource.online_endpoint.id

  body = {
    properties = {
      traffic = {
        # Nazwa musi pasować do deployment_name
        (var.deployment_name) = 100
      }
    }
  }

  depends_on = [azapi_resource.online_deployment]
}

# ─────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────

output "scoring_uri" {
  value = azapi_resource.online_endpoint.output.properties.scoringUri
}

output "endpoint_id" {
  value = azapi_resource.online_endpoint.id
}

output "environment_id" {
  value = azapi_resource.ml_environment_version.id
}
