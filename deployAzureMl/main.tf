# ─────────────────────────────────────────────
# Dane istniejących zasobów (workspace już istnieje)
# ─────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# Istniejący Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Istniejący Azure ML Workspace (Workspace1)
data "azurerm_machine_learning_workspace" "mlw" {
  name                = var.workspace_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ─────────────────────────────────────────────
# Moduł: Azure Container Registry
# ─────────────────────────────────────────────

module "acr" {
  source = "./modules/acr"

  acr_name            = var.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = var.tags
}

# ─────────────────────────────────────────────
# Moduł: Rejestracja modelu ONNX w Azure ML
# ─────────────────────────────────────────────

module "ml_model" {
  source = "./modules/ml_model"

  workspace_id     = data.azurerm_machine_learning_workspace.mlw.id
  model_name       = var.model_name
  model_version    = var.model_version
  model_local_path = var.model_local_path
  location         = data.azurerm_resource_group.rg.location
  tags             = var.tags
}

# ─────────────────────────────────────────────
# Moduł: Online Endpoint + Deployment (.NET BYOC)
# ─────────────────────────────────────────────

module "ml_endpoint" {
  source = "./modules/ml_endpoint"

  workspace_id     = data.azurerm_machine_learning_workspace.mlw.id
  location         = data.azurerm_resource_group.rg.location
  endpoint_name    = var.endpoint_name
  deployment_name  = var.deployment_name
  model_id         = module.ml_model.model_version_id
  container_image  = var.container_image
  acr_id           = module.acr.acr_id
  instance_type    = var.instance_type
  instance_count   = var.instance_count
  tags             = var.tags

  depends_on = [module.ml_model, module.acr]
}
