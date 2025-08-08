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
    key                  = "prod.tfstate"
  }
}

provider "azurerm" {
  features {}
}