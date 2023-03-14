terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2" #without specifying, latest version will be used, may break code
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.19.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "AJTerraformResourceGroup"
  location = "Canada Central"
}

