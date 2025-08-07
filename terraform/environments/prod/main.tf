terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "cst8918-final-project-group-2-storage"
    storage_account_name = "cst8918finalprojectgrp2"
    container_name       = "tfstate"
    key                  = "prod.app.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  environment         = "prod"
  location            = "Canada Central"
  resource_group_name = "cst8918-final-project-group-2"
  subnet_id           = "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/cst8918-final-project-group-2/providers/Microsoft.Network/virtualNetworks/cst8918-final-project-vnet/subnets/cst8918-final-project-prod-subnet"
}

# AKS Module for Production Environment
module "aks" {
  source              = "../../infra/modules/aks"
  environment         = local.environment
  resource_group_name = local.resource_group_name
  location            = local.location
  enable_auto_scaling = true
  minimum_node_count  = 1
  maximum_node_count  = 3
  subnet_id           = local.subnet_id
}

# Weather App Module for Test Environment