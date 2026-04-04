output "endpoint_url" {
  description = "URL Scoring endpointu (do wywołań API)"
  value       = module.ml_endpoint.scoring_uri
}

output "endpoint_name" {
  description = "Nazwa endpointu w Azure ML"
  value       = var.endpoint_name
}

output "model_id" {
  description = "ID zarejestrowanego modelu ONNX"
  value       = module.ml_model.model_version_id
}

output "acr_login_server" {
  description = "Login server ACR — użyj do budowania obrazu Docker"
  value       = module.acr.login_server
}

output "acr_id" {
  description = "Resource ID ACR"
  value       = module.acr.acr_id
}

output "workspace_id" {
  description = "Resource ID Azure ML Workspace"
  value       = data.azurerm_machine_learning_workspace.mlw.id
}

output "get_endpoint_key_command" {
  description = "Komenda CLI do pobrania klucza autoryzacji endpointu"
  value       = "az ml online-endpoint get-credentials -n ${var.endpoint_name} -g ${var.resource_group_name} -w ${var.workspace_name}"
}
