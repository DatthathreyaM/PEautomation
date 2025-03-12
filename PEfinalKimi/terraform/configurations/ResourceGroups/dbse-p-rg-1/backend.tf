terraform {
  backend "azurerm" {
    storage_account_name = "AZURECENGSA50"
    container_name       = "tfstate"
    key                  = "dbse-p-1/dbse-p-rg-1.tfstate"
    resource_group_name  = "azure-sa-rg-1"
    access_key           = var.azure_storage_access_key
  }
}