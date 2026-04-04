# -------------------------------------------------------
# Azure ML – TorchScript model deployment via OpenTofu
# -------------------------------------------------------

# ---------- Data: existing workspace ----------

data "azurerm_machine_learning_workspace" "ws" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

# ---------- 1. Register model (az ml CLI) ----------

resource "terraform_data" "model_registration" {
  triggers_replace = filemd5(var.model_local_path)

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      az ml model create `
        --workspace-name '${var.workspace_name}' `
        --resource-group '${var.resource_group_name}' `
        --name '${var.model_name}' `
        --version '${var.model_version}' `
        --path '${var.model_local_path}' `
        --type custom_model `
        --description 'TorchScript YOLO model'
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
    command     = "Write-Host 'Model archived – clean up manually in Azure ML if needed.'"
  }
}

# ---------- 2. Generate deployment YAML ----------

resource "local_file" "deployment_yaml" {
  content = templatefile("${path.module}/templates/deployment.yaml.tftpl", {
    deployment_name = var.deployment_name
    model_name      = var.model_name
    model_version   = var.model_version
    instance_type   = var.instance_type
    instance_count  = var.instance_count
  })
  filename = "${path.module}/.generated/deployment.yaml"
}

# ---------- 3. Create Managed Online Endpoint ----------

resource "azapi_resource" "online_endpoint" {
  type      = "Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2024-04-01"
  name      = var.endpoint_name
  parent_id = data.azurerm_machine_learning_workspace.ws.id
  location  = data.azurerm_machine_learning_workspace.ws.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      authMode            = "Key"
      publicNetworkAccess = "Enabled"
    }
  }
}

# ---------- 4. Create Managed Online Deployment ----------

resource "terraform_data" "deployment" {
  depends_on = [
    terraform_data.model_registration,
    azapi_resource.online_endpoint,
    local_file.deployment_yaml,
  ]

  triggers_replace = [
    filemd5(var.model_local_path),
    var.instance_type,
    var.instance_count,
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      az ml online-deployment create `
        --workspace-name '${var.workspace_name}' `
        --resource-group '${var.resource_group_name}' `
        --endpoint-name '${var.endpoint_name}' `
        --name '${var.deployment_name}' `
        --file '${path.module}/.generated/deployment.yaml' `
        --all-traffic
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
    command     = "Write-Host 'Deployment removed – endpoint itself is destroyed by azapi.'"
  }
}
