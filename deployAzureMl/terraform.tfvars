# ---- Azure ----
subscription_id     = "ea57ebd7-a799-4b02-abbc-51816dd5043e"
resource_group_name = "rg-labpl-ar-dev"
workspace_name      = "ML workspace AR"

# ---- Model ----
model_local_path = "../Exercise Files/03-02/runs/detect/train/weights/best.torchscript"
model_name       = "torchscript-yolo-model"
model_version    = "1"

# ---- Endpoint ----
endpoint_name   = "torchscript-yolo-endpoint"
deployment_name = "torchscript-yolo-deploy-1"
# Standard_D2as_v4
instance_type   = "Standard_DS2_v2"
instance_count  = 1

# ---- Environment (lightweight, installs torch via pip) ----
curated_environment = "azureml://registries/azureml/environments/minimal-py311-inference/labels/latest"
env_version         = "1"
