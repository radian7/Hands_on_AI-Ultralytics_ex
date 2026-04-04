terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  # Stan przechowywany w Azure Blob Storage
  # Odkomentuj i uzupełnij przed pierwszym `tofu init`
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unikalnysufiks>"
  #   container_name       = "tfstate"
  #   key                  = "onnx-dotnet.tfstate"
  # }
}

provider "azurerm" {
  features {}
  # Uwierzytelnianie przez: az login / Service Principal / Managed Identity
  # subscription_id = var.subscription_id  # lub zmienna środowiskowa ARM_SUBSCRIPTION_ID
}

provider "azapi" {
  # Dziedziczy uwierzytelnianie z azurerm
}
