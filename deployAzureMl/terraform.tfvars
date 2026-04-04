# ---- Azure ----
subscription_id     = "ea8144c8-6d45-4103-a569-3871a16e422c"
resource_group_name = "radian7-rg"
workspace_name      = "Workspace1"

# ---- Model ----
model_local_path = "../Exercise Files/03-02/runs/detect/train/weights/best.torchscript"
model_name       = "torchscript-yolo-model"
model_version    = "3"

# ---- Endpoint ----
endpoint_name   = "torchscript-yolo-endpoint"
deployment_name = "torchscript-yolo-deploy-1"
# Standard_D2as_v4
instance_type   = "Standard_DS2_v2"
instance_count  = 1

# ---- Environment (lightweight, installs torch via pip) ----
curated_environment = "azureml://registries/azureml/environments/minimal-py311-inference/labels/latest"
