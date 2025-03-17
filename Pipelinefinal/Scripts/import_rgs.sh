#!/bin/bash

# Inputs
SUBSCRIPTION_NAME=$1
RESOURCE_GROUP_NAME=$2

# Read subscriptions.json
SUBSCRIPTIONS=$(cat subscriptions.json | jq -c '.subscriptions[]')

for SUB in $SUBSCRIPTIONS; do
  SUB_NAME=$(echo $SUB | jq -r '.name')
  SUB_ID=$(echo $SUB | jq -r '.id')

  # Check if the subscription matches the input
  if [[ "$SUB_NAME" == "$SUBSCRIPTION_NAME" ]]; then
    echo "Subscription ID: $SUB_ID"
    echo "Subscription Name: $SUB_NAME"

    # Determine environment (prod or non-prod)
    if [[ "$SUB_NAME" =~ ^(dbse-p-1|dbsm-p-1) ]]; then
      echo "Environment: prod"
    elif [[ "$SUB_NAME" =~ ^(dbse-n-1|dbsm-n-1) ]]; then
      echo "Environment: non-prod"
    else
      echo "Environment: unknown"
    fi

    # Fetch resource groups for the subscription
    if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
      # Import all RGs in the subscription
      RG_LIST=$(az group list --subscription $SUB_ID --query "[].{name:name, location:location, subscription_id:id, tags:tags}" -o json)
    else
      # Import a specific RG
      RG_LIST=$(az group show --subscription $SUB_ID --name "$RESOURCE_GROUP_NAME" --query "{name:name, location:location, subscription_id:id, tags:tags}" -o json | jq -c '.')
    fi

    for RG in $(echo $RG_LIST | jq -c '.[]'); do
      RG_NAME=$(echo $RG | jq -r '.name')
      RG_LOCATION=$(echo $RG | jq -r '.location')
      RG_SUBSCRIPTION_ID=$(echo $RG | jq -r '.subscription_id')
      RG_TAGS=$(echo $RG | jq -r '.tags')

      # Create directory for the resource group
      mkdir -p "terraform/configurations/$SUB_NAME/$RG_NAME"

      # Save RG details to $resource_group.json
      echo $RG | jq '.' > "terraform/configurations/$SUB_NAME/$RG_NAME/resource_group.json"

      # Create main.tf using the RG module
      cat <<EOF > "terraform/configurations/$SUB_NAME/$RG_NAME/main.tf"
provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../../modules/resource_group"

  name           = "$RG_NAME"
  location       = "$RG_LOCATION"
  tags           = $RG_TAGS
  subscription_id = "$RG_SUBSCRIPTION_ID"
}

terraform {
  backend "azurerm" {
    storage_account_name = "AZURECENGSA50"
    container_name       = "tfstate"
    key                  = "$SUB_NAME/$RG_NAME.tfstate"
    resource_group_name  = "azure-sa-rg-1"
    access_key           = var.azure_storage_access_key
  }
}
EOF

      # Create variables.tf
      cat <<EOF > "terraform/configurations/$SUB_NAME/$RG_NAME/variables.tf"
variable "azure_storage_access_key" {
  type = string
}
EOF

      # Initialize Terraform
      cd "terraform/configurations/$SUB_NAME/$RG_NAME"
      terraform init

      # Import the resource group using the module
      terraform import module.resource_group.azurerm_resource_group.rg /subscriptions/$RG_SUBSCRIPTION_ID/resourceGroups/$RG_NAME

      cd ../../../..
    done
  fi
done