resource "azurerm_redis_cache" "main_cache" {
  name                = "${var.environment}-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"

  tags = {
    environment = var.environment
  }
}