output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value = {
    prod  = azurerm_subnet.prod.id
    test  = azurerm_subnet.test.id
    dev   = azurerm_subnet.dev.id
    admin = azurerm_subnet.admin.id
  }
}

output "subnet_names" {
  description = "Names of the subnets"
  value = {
    prod  = azurerm_subnet.prod.name
    test  = azurerm_subnet.test.name
    dev   = azurerm_subnet.dev.name
    admin = azurerm_subnet.admin.name
  }
}
