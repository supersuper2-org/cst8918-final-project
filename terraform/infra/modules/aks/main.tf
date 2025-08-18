resource "azurerm_kubernetes_cluster" "aks" {
  name                  = "${var.environment}-aks"
  location              = var.location
  resource_group_name   = var.resource_group_name
  dns_prefix            = "${var.environment}-aks"
  sku_tier              = "Standard"
  cost_analysis_enabled = true

  default_node_pool {
    name                 = "masterpool"
    node_count           = 1
    vm_size              = "Standard_B2s"
    vnet_subnet_id       = var.subnet_id
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.minimum_node_count
    max_count            = var.maximum_node_count
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  tags = {
    environment = var.environment
  }
}

# # 3. Create the Role Assignment
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   # The principal_id of the AKS cluster's Managed Identity
#   principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id

#   # The role definition ID for 'AcrPull'
#   # You can use a data source to get this dynamically, or hardcode the well-known ID.
#   # Using a data source is more robust across Azure regions/environments.
#   role_definition_name = "AcrPull"

#   # The scope is the ID of the Azure Container Registry resource
#   scope = var.acr_id

#   # Optional: Delay creation until AKS cluster is ready (avoids race conditions)
#   depends_on = [
#     azurerm_kubernetes_cluster.aks # Ensure AKS cluster is deployed first
#   ]
# }