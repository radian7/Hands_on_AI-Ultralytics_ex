# -------------------------------------------------------
# Azure ML – TorchScript model deployment via OpenTofu
# -------------------------------------------------------

# ---------- Data: existing workspace ----------

data "azurerm_machine_learning_workspace" "ws" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

# ---------- 1. Register model (az ml CLI) ----------
# show dla idempotetntosci

resource "terraform_data" "model_registration" {
  triggers_replace = filemd5(var.model_local_path)

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $modelExists = az ml model show `
        --name '${var.model_name}' `
        --version '${var.model_version}' `
        --workspace-name '${var.workspace_name}' `
        --resource-group '${var.resource_group_name}' `
        --query name -o tsv 2>$null
      if ($modelExists) {
        Write-Host "Model '${var.model_name}:${var.model_version}' already registered – skipping."
      } else {
        az ml model create `
          --workspace-name '${var.workspace_name}' `
          --resource-group '${var.resource_group_name}' `
          --name '${var.model_name}' `
          --version '${var.model_version}' `
          --path '${var.model_local_path}' `
          --type custom_model `
          --description 'TorchScript YOLO model'
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      }
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
    env_version     = var.env_version
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

  response_export_values = ["*"]
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
      $ErrorActionPreference = 'Continue'

      # Wait for endpoint to reach Succeeded state
      Write-Host "Waiting for endpoint '${var.endpoint_name}' to be ready..."
      $maxWait = 30
      $attempt = 0
      do {
        Start-Sleep -Seconds 10
        $attempt++
        $state = az ml online-endpoint show `
          --name '${var.endpoint_name}' `
          --workspace-name '${var.workspace_name}' `
          --resource-group '${var.resource_group_name}' `
          --query 'provisioning_state' -o tsv 2>$null
        Write-Host "  attempt $attempt/$maxWait – state: $state"
      } until ($state -eq 'Succeeded' -or $attempt -ge $maxWait)

      if ($state -ne 'Succeeded') {
        Write-Error "Endpoint did not reach Succeeded state after $maxWait attempts (last state: $state)"
        exit 1
      }

      # Check if deployment already exists (ignore non-zero exit from show)
      az ml online-deployment show `
        --name '${var.deployment_name}' `
        --endpoint-name '${var.endpoint_name}' `
        --workspace-name '${var.workspace_name}' `
        --resource-group '${var.resource_group_name}' `
        --query name -o tsv 2>$null | Out-Null
      $deployExists = $LASTEXITCODE -eq 0

      if ($deployExists) {
        Write-Host "Deployment '${var.deployment_name}' already exists – skipping create."
      } else {
        az ml online-deployment create `
          --workspace-name '${var.workspace_name}' `
          --resource-group '${var.resource_group_name}' `
          --endpoint-name '${var.endpoint_name}' `
          --name '${var.deployment_name}' `
          --file '${path.module}/.generated/deployment.yaml' `
          --all-traffic
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      }
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
    command     = "Write-Host 'Deployment removed – endpoint itself is destroyed by azapi.'"
  }
}
