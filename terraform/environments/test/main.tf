terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "cst8918-final-project-group-2-storage"
    storage_account_name = "cst8918finalprojectgrp2"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  environment = "prod"
  location    = "East US"
  tags = {
    Environment = local.environment
    Project     = "CST8918Final"
    Team        = "Group"
  }
}

# Network Module
module "network" {
  source = "infra/modules/network"

  resource_group_name = "cst8918-final-project-group-2-storage"
  location            = local.location
  environment         = local.environment
  tags                = local.tags
}

# AKS Module for Production Environment
module "aks" {
  source = "infra/modules/aks"

  resource_group_name = module.network.resource_group_name
  location            = local.location
  environment         = local.environment
  subnet_id           = module.network.test_subnet_id
  node_count          = 1
  enable_auto_scaling = false
  tags                = local.tags
}

# Weather App Module for Test Environment