data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "cst8918-final-project-group-2-storage"
    storage_account_name = "cst8918finalprojectgrp2"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
  }
}

# AKS Module for Production Environment
module "aks" {
  source              = "../../infra/modules/aks"
  environment         = "prod"
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  enable_auto_scaling = true
  minimum_node_count  = 1
  maximum_node_count  = 3
  subnet_id           = data.terraform_remote_state.infra.outputs.prod_subnet_id
  service_cidr        = "10.5.0.0/16"
  dns_service_ip      = "10.5.0.10"
  #acr_id              = data.terraform_remote_state.infra.outputs.container_registry_id
}

# Redis Module for Test Environment
module "redis" {
  source              = "../../infra/modules/redis"
  environment         = "prod"
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  depends_on          = [ module.aks ]
}

module "weather_app" {
  source                     = "../../infra/modules/weather-app"
  k8s_host                   = module.aks.host
  k8s_client_certificate     = base64decode(module.aks.client_certificate)
  k8s_client_key             = base64decode(module.aks.client_key)
  k8s_cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  redis_hostname             = module.redis.redis_hostname
  redis_ssl_port             = module.redis.redis_ssl_port
  redis_primary_key          = module.redis.redis_primary_key
  acr_login_server           = "${data.terraform_remote_state.infra.outputs.container_registry_name}.azurecr.io"
  openweather_api_key        = var.weather_api_key
  acr_username               = var.acr_username
  acr_password               = var.acr_password
  app_image_tag              = var.app_image_tag
  depends_on                 = [ module.aks, module.redis ]
}