terraform {

  required_version = ">= 1.5"

  backend "azurerm" {
    resource_group_name  = "cst8918-final-project-group-2-storage" # Replace with your RG from tf-backend
    storage_account_name = "cst8918finalprojectgrp2"               # Replace with your Storage Account name
    container_name       = "tfstate"
    key                  = "prod.app.tfstate"
    use_oidc             = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}