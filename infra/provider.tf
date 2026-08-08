terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        # version = "5.0.0" // Use dotnet_version = "10.0"
        version = "4.46.0" // Use dotnet_version = "9.0"
        # version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Create the resources to store the Terraform state in Azure Blob Storage

# az resource group create --name <resource_group_name> --location <location>
# az storage account create --name <storage_account_name> --resource-group <resource_group_name> --location <location> --sku Standard_LRS
# az storage container create --name <container_name> --account-name <storage_account_name>

# az resource group create --name serverless-rg --location <location>
# az storage account create --name tfstateserverless --resource-group serverless-rg --location <location> --sku Standard_LRS
# az storage container create --name tfstate --account-name tfstateserverless