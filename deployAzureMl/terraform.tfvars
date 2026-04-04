# ---- Azure ----
subscription_id     = "ea8144c8-6d45-4103-a569-3871a16e422c"
resource_group_name = "radian7-rg"
workspace_name      = "Workspace1"

# ---- Model ----
model_local_path = "Exercise Files/03-02/runs/detect/train/weights/best.torchscript"
model_name       = "torchscript-yolo-model"
model_version    = "1"

# ---- Endpoint ----
endpoint_name   = "torchscript-endpoint"
deployment_name = "torchscript-deploy-1"
instance_type   = "Standard_DS3_v2"
instance_count  = 1

# ---- Environment (curated PyTorch CPU) ----
curated_environment = "azureml://registries/azureml/environments/pytorch-2.2-ubuntu22.04-py310-cpu/labels/latest"
