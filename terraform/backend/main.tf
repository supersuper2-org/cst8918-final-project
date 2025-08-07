terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  use_oidc = true
}

# Resource Group for Terraform backend
resource "azurerm_resource_group" "rg" {
  name     = "cst8918-final-project-group-2-storage"
  location = "Canada Central"
}

# Storage Account for state files
resource "azurerm_storage_account" "storage" {
  name                     = "cst8918finalprojectgrp2"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Container for tfstate
resource "azurerm_storage_container" "container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
