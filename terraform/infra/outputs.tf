output "resource_group_name" {
  description = "The name of the resource group for the application."
  value       = azurerm_resource_group.main_rg.name
}

output "resource_group_location" {
  description = "The location of the resource group."
  value       = azurerm_resource_group.main_rg.location
}

output "container_registry_name" {
  description = "The name of the Azure Container Registry."
  value       = azurerm_container_registry.acr.name
}

output "prod_subnet_id" {
  description = "The ID of the production subnet."
  value       = module.network.subnet_ids.prod
}

output "test_subnet_id" {
  description = "The ID of the test subnet."
  value       = module.network.subnet_ids.test
}