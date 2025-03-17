resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

# Example: Use subscription_id in the module (if needed)
output "subscription_id" {
  value = var.subscription_id
}