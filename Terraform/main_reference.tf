# this terraform script does the following:
#
#   creates a dbricks developer group in the format companyname_dbricks_dev
#   creates a dbricks app group in the format companyname_dbricks_app
#   creates a service principal and adds it to the dbricks app group
#   adds permissions required by the dakota solution to the app service principal
#   creates a resource group to house the azure dbricks resources
#   adds the dev and app groups as contributor to the resource group
#   creates a storage account for logs
#   creates a storage account and container for data lake for use by dbricks
#   adds the dev and app groups as storage blob contributor to the storage accounts
#   creates a key vault and adds the dev and app groups as key vault secrets officer
#   creates an automation account and adds the managed identity into the app group
#   creates a log analytics workspace for diagnostics
#   creates two logic apps for use to send emails for failed pipelines and manage secrets
#   creates a dbricks workspace and sets the sqladmin password as per variables
#   creates a dbricks firewall rule to add the current user to create access for roles
#   adds the dev and app groups to dbricks admin and sql admin
#   creates a sql dedicated pool in the dbricks workspace !!does not pause the pool!!
#   creates key vault secrets for all relevant items
#   creates diagnostics setting for pipeline runs and activities
#
# this terraform script does not do:
#
#   create microsoft defender
#   create dbricks / sql audit
#   deploy managed virtual network or private endpoints for dbricks
#   create spark pools
#   create named users or alter user permissions
#   set any firewall rules aside from the current logged in user
#   set any encryption rules
#   create any automation scripts or update any automation modules
#   set the required settings in Power BI tenant admin
#   create a devops workspace
#   connect dbricks with a devops workspace
#   install a self-hosted runtime to connect to on-prem resources
#   deploy any notebooks, pipelines, linked services or datasets to dbricks workspace
#   create a sql serverless database

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

provider "azuread" { #local name for provider to be used

}
provider "azurerm1" { #local name for provider to be used
  features {}        #required block
}

#set current users ip
data "http" "currentip" {
  url = "http://ipv4.icanhazip.com"
}


#set current subscription to variable
data "azurerm_subscription" "primary" {}

#set current user to variable
data "azuread_client_config" "current" {}

#create developer AD group
resource "azuread_group" "dbricks_dev_group" {
  display_name            = "${var.company_name}_dbricks_dev" #required
  prevent_duplicate_names = true
  security_enabled        = true #required if not mail enabled

  owners = [
    data.azuread_client_config.current.object_id #set owner to current user
  ]
}

#add the current user into the developer group
resource "azuread_group_member" "add_user_to_developer_group" {
  group_object_id  = azuread_group.dbricks_dev_group.id
  member_object_id = data.azuread_client_config.current.object_id
}

#create application AD group for use in Power BI
resource "azuread_group" "dbricks_app_group" {
  display_name            = "${var.company_name}_dbricks_app" #required
  prevent_duplicate_names = true
  security_enabled        = true #required if not mail enabled

  owners = [
    data.azuread_client_config.current.object_id #set owner to current user
  ]
}

#create application and service principal with password
resource "azuread_application" "dbricks_app" {
  display_name = "${var.company_name}dbricksappserviceprincipal"
  owners       = [data.azuread_client_config.current.object_id]#
  #these are application permissions and cover the scope of microsoft graph and sharepoint
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph#
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61" # Directory.Read.All
      type = "Role"
    }#
    resource_access {
      id   = "01d4889c-1287-42c6-ac1f-5d1e02578ef6" # Files.Read.All
      type = "Role"
    }#
    resource_access {
      id   = "5b567255-7703-4780-807c-7be8301ae99b" # Group.Read.All
      type = "Role"
    }#
    resource_access {
      id   = "658aa5d8-239f-45c4-aa12-864f4fc7e490" # Member.Read.Hidden
      type = "Role"
    }#
    resource_access {
      id   = "332a536c-c7ef-4017-ab91-336970924f0d" # Sites.Read.All
      type = "Role"
    }#
    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type = "Role"
    }
  }
}

#creates ad service principal for app
resource "azuread_service_principal" "dbricks_app" {
  application_id               = azuread_application.dbricks_app.application_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = true
  use_existing                 = true
}

resource "azuread_service_principal_password" "dbricks_app" {
  service_principal_id = azuread_service_principal.dbricks_app.object_id
  end_date_relative    = "17520h" #2 years
}

#create resource group to manage dbricks resources
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.company_name}dbricksresourcegroup" #required
  location = var.deployment_location               #required, one of ['Canada Central', 'West US', 'West US 2', 'West US 3']
}

#assign contributor role for developer group
resource "azurerm_role_assignment" "resource_group_dev_contributor" {
  scope                = azurerm_resource_group.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.dbricks_dev_group.id
}

#assign contributor role for app group
resource "azurerm_role_assignment" "resource_group_app_contributor" {
  scope                = azurerm_resource_group.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.dbricks_app_group.id
}

#this step creates the non hierarchical storage in LRS with soft deletes disabled
#these settings are required to enable log diagnotsics from synapse pipelines (dont need)
#resource "azurerm_storage_account" "storage_account_logs" {
#  name                     = "${var.company_name}syndatalogs"               #required
#  resource_group_name      = azurerm_resource_group.resource_group.name     #required
#  location                 = azurerm_resource_group.resource_group.location #required
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  account_kind             = "StorageV2"
#  #blob and container delete retention policies specifically not added
#  #soft deletes are set to disabled
#}
#
##assign storage blob data contributor role for developer group to datalogs
#resource "azurerm_role_assignment" "datalogs_dev_contributor" {
#  scope                = azurerm_storage_account.storage_account_logs.id
#  role_definition_name = "Storage Blob Data Contributor"
#  principal_id         = azuread_group.dbricks_dev_group.id
#}
#
##assign storage blob data contributor role for app group to datalogs
#resource "azurerm_role_assignment" "datalogs_app_contributor" {
#  scope                = azurerm_storage_account.storage_account_logs.id
#  role_definition_name = "Storage Blob Data Contributor"
#  principal_id         = azuread_group.dbricks_app_group.id
#}

#this step creates the hierarchical storage/datalake for dbricks workspace
resource "azurerm_storage_account" "storage_account_lake" {
  name                     = "${var.company_name}dbricksdatalake"               #required
  resource_group_name      = azurerm_resource_group.resource_group.name     #required
  location                 = azurerm_resource_group.resource_group.location #required
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true" #hierarchical name storage

  blob_properties {
    delete_retention_policy {
      days = 90
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

#this step creates the container in the data lake
resource "azurerm_storage_data_lake_gen2_filesystem" "storage_account_lake_container" {
  name               = "${var.company_name}dbricksdatalake"
  storage_account_id = azurerm_storage_account.storage_account_lake.id
}

#assign storage blob data contributor role for developer group to datalake
resource "azurerm_role_assignment" "datalake_dev_contributor" {
  scope                = azurerm_storage_account.storage_account_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.dbricks_dev_group.id
}

#assign storage blob data contributor role for app group to datalake
resource "azurerm_role_assignment" "datalake_app_contributor" {
  scope                = azurerm_storage_account.storage_account_lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.dbricks_app_group.id
}

#this step creates a key vault and sets it to role based access control
resource "azurerm_key_vault" "key_vault" {
  name                        = "${var.company_name}dbrickskeyvault"               #required
  location                    = azurerm_resource_group.resource_group.location #required
  resource_group_name         = azurerm_resource_group.resource_group.name     #required
  enabled_for_disk_encryption = true
  tenant_id                   = data.azuread_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

#assign keyvault secrets officer role for current user to keyvault
resource "azurerm_role_assignment" "keyvault_user_contributor" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azuread_client_config.current.object_id
}

#assign keyvault secrets officer role for developer group to keyvault
resource "azurerm_role_assignment" "keyvault_dev_contributor" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_group.dbricks_dev_group.id
}

#assign storage blob data contributor role for app group to keyvault
resource "azurerm_role_assignment" "keyvault_app_contributor" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_group.dbricks_app_group.id
}

#this step creates an automation account to run dataset refreshes and other tasks for dbricks
resource "azurerm_automation_account" "automation_account" {
  name                = "${var.company_name}dbricksautomation"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

#add the automation account managed identity into the app developer group
resource "azuread_group_member" "add_automation_to_app" {
  group_object_id  = azuread_group.dbricks_app_group.id
  member_object_id = azurerm_automation_account.automation_account.identity[0].principal_id
}

#this step creates a log analytics workspace for dbricks
#resource "azurerm_log_analytics_workspace" "example" {
#  name                = "${var.company_name}dbricksloganalytics"
#  location            = azurerm_resource_group.resource_group.location
#  resource_group_name = azurerm_resource_group.resource_group.name
#  retention_in_days   = 90
#}

#this step creates a blank logic app for sending emails
#resource "azurerm_logic_app_workflow" "sendemail_logic_app" {
#  name                = "${var.company_name}sendemail"
#  location            = azurerm_resource_group.resource_group.location
#  resource_group_name = azurerm_resource_group.resource_group.name
#}

#this step creates a blank logic app for managing secrets
resource "azurerm_logic_app_workflow" "secretmanager_logic_app" {
  name                = "${var.company_name}secretmgr"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

#2022-04-01 to 2022-04-06 dbricks workspaces were disabled for pay as you go subscriptions
#May error until Microsoft fixes

#this step creates the dbricks workspace
#additional decisions
# do we need firewall set up? company ip, developer home ip? are developers VPN to company ip?
# do we need Microsoft Defender for Cloud enabled? additional monthly cost
# do we need Azure SQL Auditing enabled? additional monthly cost
# do we need to deploy to managed virtual network and manage private endpoints? additional management overhead and compute delays
#resource "azurerm_dbricks_workspace" "dbricks_workspace" {
#  name                                 = "${var.company_name}synworkspace"
#  resource_group_name                  = azurerm_resource_group.resource_group.name
#  location                             = azurerm_resource_group.resource_group.location
#  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.storage_account_lake_container.id
#  sql_administrator_login              = "sqladminuser"
#  sql_administrator_login_password     = var.sqladmin_password
#
#  aad_admin {
#    login     = azuread_group.dbricks_dev_group.display_name
#    object_id = azuread_group.dbricks_dev_group.object_id
#    tenant_id = data.azuread_client_config.current.tenant_id
#  }
#
#  identity {
#    type = "SystemAssigned"
#  }
#
#}

resource "azurerm_databricks_workspace" "dbricks_workspace" {
  name                        = "${var.company_name}dbricksworkspace"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = azurerm_resource_group.resource_group.location
  sku                         = "premium"
  managed_resource_group_name = "${var.company_name}-workspace-rg"
  #tags                        = local.tags
}


#adds a delay between workspace creation and firewall creation
#resource "time_sleep" "wait_dbricks_workspace_10s" {
#  create_duration = "10s"
#  depends_on = [
#    azurerm_dbricks_workspace.dbricks_workspace
#  ]
#}
#
##adds current user IP to firewall
#resource "azurerm_dbricks_firewall_rule" "add_current_user" {
#  name                 = "Allow_Deployment_User"
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  start_ip_address     = chomp(data.http.currentip.body)
#  end_ip_address       = chomp(data.http.currentip.body)
#
#  depends_on = [
#    time_sleep.wait_dbricks_workspace_10s
#  ]
#}
#
##adds a delay between firewall creation and role creation
#resource "time_sleep" "wait_dbricks_firewall_20s" {
#  create_duration = "20s"
#  depends_on = [
#    azurerm_dbricks_firewall_rule.add_current_user
#  ]
#}
#
##adds sql admin to dev group
#resource "azurerm_dbricks_role_assignment" "sql_admin_dev" {
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  role_name            = "dbricks SQL Administrator"
#  principal_id         = azuread_group.dbricks_dev_group.id
#
#  depends_on = [
#    time_sleep.wait_dbricks_firewall_20s
#  ]
#}
#
##these roles depend on the current user having access to dbricks workspace through the firewall
##may fail these steps, please just run terraform apply again to ensure these are created
##adds sql admin to app group
#resource "azurerm_dbricks_role_assignment" "sql_admin_app" {
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  role_name            = "dbricks SQL Administrator"
#  principal_id         = azuread_group.dbricks_app_group.id
#
#  depends_on = [
#    time_sleep.wait_dbricks_firewall_20s
#  ]
#}
#
##adds dbricks admin to dev group
#resource "azurerm_dbricks_role_assignment" "dbricks_admin_dev" {
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  role_name            = "dbricks Administrator"
#  principal_id         = azuread_group.dbricks_dev_group.id
#
#  depends_on = [
#    time_sleep.wait_dbricks_firewall_20s
#  ]
#}
#
##adds dbricks admin to app group
#resource "azurerm_dbricks_role_assignment" "dbricks_admin_app" {
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  role_name            = "dbricks Administrator"
#  principal_id         = azuread_group.dbricks_app_group.id
#
#  depends_on = [
#    time_sleep.wait_dbricks_firewall_20s
#  ]
#}
#
##add the dbricks account managed identity into the app developer group
#resource "azuread_group_member" "add_dbricks_to_app" {
#  group_object_id  = azuread_group.dbricks_app_group.id
#  member_object_id = azurerm_dbricks_workspace.dbricks_workspace.identity[0].principal_id
#}
#
##create dbricks sql pool
##additional decisions
## do we turn on diagnostic settings for sqlrequests, requeststeps, execrequests, dmsworkers, waits?
## do we turn on Microsoft Defender for Cloud?
## do we have any data that requires masking?
## do we turn on SQL Auditing
## remember to pause pool if not being used immediately
#resource "azurerm_dbricks_sql_pool" "dbricks_workspace" {
#  name                 = "${var.company_name}sqldedicated"
#  dbricks_workspace_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  sku_name             = "DW100c"
#  create_mode          = "Default"
#}
#
##create dbricks diagnostic policy - send pipeline, activity, trigger runs to logs
#resource "azurerm_monitor_diagnostic_setting" "dbricks_workspace" {
#  name               = "dbricks_pipeline_diagnostic_logs"
#  target_resource_id = azurerm_dbricks_workspace.dbricks_workspace.id
#  storage_account_id = azurerm_storage_account.storage_account_logs.id
#
#  log {
#    category = "IntegrationPipelineRuns"
#    enabled  = true
#
#    retention_policy {
#      enabled = true
#      days    = 9
#    }
#  }
#
#  log {
#    category = "IntegrationActivityRuns"
#    enabled  = true
#
#    retention_policy {
#      enabled = true
#      days    = 9
#    }
#  }
#
#  log {
#    category = "IntegrationTriggerRuns"
#    enabled  = true
#
#    retention_policy {
#      enabled = true
#      days    = 9
#    }
#  }
#}
#
##add the sqladminuser password to keyvault
#resource "azurerm_key_vault_secret" "key_vault" {
#  name         = "dbricks-sqladminuser-password"
#  value        = var.sqladmin_password
#  key_vault_id = azurerm_key_vault.key_vault.id
#  depends_on = [
#    azurerm_role_assignment.keyvault_user_contributor
#  ]
#}
#
##add the service principal password to keyvault
#resource "azurerm_key_vault_secret" "sp_password" {
#  name         = "dbricks-serviceprincipal-password"
#  value        = azuread_service_principal_password.dbricks_app.value
#  key_vault_id = azurerm_key_vault.key_vault.id
#  depends_on = [
#    azurerm_role_assignment.keyvault_user_contributor
#  ]
#}
#
##add encrypted value to data output
#data "template_file" "service_principal_secret" {
#  template = azuread_service_principal_password.dbricks_app.value
#}
#
##output the password to console for confirmation
#output "service_principal_password" {
#  value      = data.template_file.service_principal_secret.rendered
#  sensitive  = false
#  depends_on = [azurerm_key_vault_secret.sp_password]
#}
#
##add the service principal appid to keyvault
#resource "azurerm_key_vault_secret" "sp_appid" {
#  name         = "dbricks-serviceprincipal-appid"
#  value        = azuread_service_principal_password.dbricks_app.id
#  key_vault_id = azurerm_key_vault.key_vault.id
#  depends_on = [
#    azurerm_role_assignment.keyvault_user_contributor
#  ]
#}
#
##add the tenantid to keyvault
#resource "azurerm_key_vault_secret" "tenantid" {
#  name         = "dbricks-tenantid"
#  value        = data.azuread_client_config.current.tenant_id
#  key_vault_id = azurerm_key_vault.key_vault.id
#  depends_on = [
#    azurerm_role_assignment.keyvault_user_contributor
#  ]
#}