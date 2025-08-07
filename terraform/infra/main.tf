
# Create the resource group for this environment
resource "azurerm_resource_group" "main_rg" {
  name     = "${var.label_prefix}-group-2"
  location = var.location
}

# Example usage of the network module (passing resource group)
module "network" {
  source            = "./modules/network"
  label_prefix      = var.label_prefix
  location          = var.location
  resource_group    = azurerm_resource_group.main_rg.name
}