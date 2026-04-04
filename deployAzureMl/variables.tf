# ---------------------
# Azure / Subscription
# ---------------------
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group containing the Azure ML workspace"
}

variable "workspace_name" {
  type        = string
  description = "Existing Azure ML workspace name"
  default     = "Workspace1"
}

# ---------------------
# Model
# ---------------------
variable "model_local_path" {
  type        = string
  description = "Local path to the TorchScript model file (.torchscript)"
}

variable "model_name" {
  type        = string
  description = "Model name registered in Azure ML"
  default     = "torchscript-yolo-model"
}

variable "model_version" {
  type        = string
  description = "Model version"
  default     = "1"
}

# ---------------------
# Endpoint & Deployment
# ---------------------
variable "endpoint_name" {
  type        = string
  description = "Managed online endpoint name (must be unique in the region)"
  default     = "torchscript-endpoint"
}

variable "deployment_name" {
  type        = string
  description = "Deployment name within the endpoint"
  default     = "torchscript-deploy-1"
}

variable "curated_environment" {
  type        = string
  description = "Azure ML curated environment URI"
  default     = "azureml://registries/azureml/environments/minimal-py311-inference/labels/latest"
}

variable "instance_type" {
  type        = string
  description = "VM size for the managed online deployment"
  default     = "Standard_DS2_v2"
}

variable "instance_count" {
  type        = number
  description = "Number of instances behind the endpoint"
  default     = 1
}
