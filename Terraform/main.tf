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
  backend "azurerm" {
        subscription_id      = "f6fcb95e-6b4e-41e8-96f9-44fb1dfd8c22"
        tenant_id            = "e7b21e91-c04e-4b80-9ce7-2456ee9519cd"
        client_id            = "a3c9abce-1170-485c-8d3f-4def849160ab"
        client_secret        = "GQH8Q~gvpVNFkyzXw_79Ajb-vqbrjSOQozZ6tahc"
        resource_group_name  = "AJDatabricksSetupResourceGroup"
        storage_account_name = "ajdatabrickssetupsa"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}
#access secret value GQH8Q~gvpVNFkyzXw_79Ajb-vqbrjSOQozZ6tahc
#access secret ID    a0df064e-4c12-4403-b727-96b3b57f620e
provider "azurerm" {
  features {} 
  subscription_id             = "${var.subscription_id}"
  tenant_id                   = "${var.tenant_id}"
  client_id                   = "${var.client_id}"
  client_secret               = "${var.client_secret}"
}


#this step creates a key vault and sets it to role based access control
resource "azurerm_key_vault" "key_vault" {
  name                        = "Vincenzooooooookeyvault"               #required
  location                    = "${var.location}" 
  resource_group_name         = "${var.resource_group_name}"    #required
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.tenant_id}"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}