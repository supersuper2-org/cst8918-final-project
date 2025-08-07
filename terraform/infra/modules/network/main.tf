resource "azurerm_virtual_network" "main" {
  name                = "${var.label_prefix}-vnet"
  address_space       = ["10.0.0.0/14"]
  location            = var.location
  resource_group_name = var.resource_group
}

resource "azurerm_subnet" "prod" {
  name                 = "${var.label_prefix}-prod-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "test" {
  name                 = "${var.label_prefix}-test-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "dev" {
  name                 = "${var.label_prefix}-dev-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "admin" {
  name                 = "${var.label_prefix}-admin-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.3.0.0/16"]
}
