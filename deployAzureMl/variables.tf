variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Nazwa istniejącej Resource Group, w której jest Workspace1"
  type        = string
}

variable "location" {
  description = "Region Azure (musi pasować do regionu workspace)"
  type        = string
  default     = "West Europe"
}

variable "workspace_name" {
  description = "Nazwa istniejącego Azure ML Workspace"
  type        = string
  default     = "Workspace1"
}

variable "acr_name" {
  description = "Nazwa Azure Container Registry (globalnie unikalna, tylko litery i cyfry)"
  type        = string
  # Przykład: "acronnxinference"
}

variable "model_name" {
  description = "Nazwa modelu w Azure ML Registry"
  type        = string
  default     = "onnx-dotnet-model"
}

variable "model_version" {
  description = "Wersja modelu"
  type        = string
  default     = "1"
}

variable "model_local_path" {
  description = "Ścieżka lokalna do pliku model.onnx (relatywna do katalogu infra/)"
  type        = string
  default     = "../model.onnx"
}

variable "endpoint_name" {
  description = "Nazwa Online Endpoint w Azure ML"
  type        = string
  default     = "onnx-dotnet-endpoint"
}

variable "deployment_name" {
  description = "Nazwa deployment (np. blue/green)"
  type        = string
  default     = "dotnet-blue"
}

variable "container_image" {
  description = "Pełny tag obrazu Docker z .NET API, np. myacr.azurecr.io/onnx-api:1.0.0"
  type        = string
}

variable "instance_type" {
  description = "Typ VM dla endpointu. CPU: Standard_DS3_v2, GPU: Standard_NC6s_v3"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "instance_count" {
  description = "Liczba instancji"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Środowisko (dev/staging/prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tagi Azure nakładane na wszystkie zasoby"
  type        = map(string)
  default = {
    project     = "onnx-inference"
    runtime     = "dotnet"
    framework   = "onnx"
    managed_by  = "opentofu"
  }
}
