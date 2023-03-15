#this step creates a key vault and sets it to role based access control
resource "azurerm_key_vault" "key_vault" {
  name                        = each.value               #required
  location                    = "${var.location}" 
  resource_group_name         = "${var.resource_group_name}"    #required
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.tenant_id}"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "${var.databricks_sku}" 
  enable_rbac_authorization   = true
  for_each = toset(var.key_vault_names)
}