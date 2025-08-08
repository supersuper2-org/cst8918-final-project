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
  }

  tags = {
    environment = var.environment
  }
}