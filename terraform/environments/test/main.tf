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
  environment         = "test"
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  enable_auto_scaling = false
  minimum_node_count  = 1
  maximum_node_count  = 1
  subnet_id           = data.terraform_remote_state.infra.outputs.test_subnet_id
}

# Redis Module for Test Environment
module "redis" {
  source              = "../../infra/modules/redis"
  environment         = "test"
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
}