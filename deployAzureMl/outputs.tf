output "workspace_id" {
  description = "Azure ML workspace resource ID"
  value       = data.azurerm_machine_learning_workspace.ws.id
}

output "endpoint_name" {
  description = "Managed online endpoint name"
  value       = azapi_resource.online_endpoint.name
}

output "endpoint_scoring_uri" {
  description = "Scoring URI (available after deployment is live)"
  value       = try(jsondecode(azapi_resource.online_endpoint.output).properties.scoringUri, "pending – deploy first")
}
