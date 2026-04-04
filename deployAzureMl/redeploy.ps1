# Aktualizuje deployment scoring scriptu bez modyfikacji infrastruktury (Terraform).
# Uzyj tego skryptu po kazdej zmianie score.py lub conda.yaml.
#
# Uzycie:
#   .\redeploy.ps1

$ErrorActionPreference = "Stop"

$RESOURCE_GROUP  = "radian7-rg"
$WORKSPACE_NAME  = "Workspace1"
$ENDPOINT_NAME   = "torchscript-yolo-endpoint"
$DEPLOYMENT_NAME = "torchscript-yolo-deploy-1"
$DEPLOYMENT_FILE = "$PSScriptRoot\.generated\deployment.yaml"

if (-not (Test-Path $DEPLOYMENT_FILE)) {
    Write-Error "Brak pliku $DEPLOYMENT_FILE. Uruchom najpierw: tofu apply"
    exit 1
}

Write-Host "Aktualizuje deployment '$DEPLOYMENT_NAME' na endpoincie '$ENDPOINT_NAME'..."

az ml online-deployment update `
    --name            $DEPLOYMENT_NAME `
    --endpoint-name   $ENDPOINT_NAME `
    --resource-group  $RESOURCE_GROUP `
    --workspace-name  $WORKSPACE_NAME `
    --file            $DEPLOYMENT_FILE

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment update zakonczony bledem (exit code $LASTEXITCODE)"
    exit $LASTEXITCODE
}

Write-Host "Gotowe. Deployment zaktualizowany pomyslnie."
