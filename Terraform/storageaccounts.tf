#this step creates the hierarchical storage/datalake for unity catalog
resource "azurerm_storage_account" "storage_account_lake" {
  name                     = each.value              #required
  resource_group_name      = "${var.resource_group_name}"     #required
  location                 = "${var.location}" #required
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true" #hierarchical name storage
  for_each = toset(var.storage_account_names)
  blob_properties {
    delete_retention_policy {
      days = 90
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}