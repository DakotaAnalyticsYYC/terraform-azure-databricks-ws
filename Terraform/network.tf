resource "azurerm_virtual_network" "this" {
  name = "aj_databricks_virtual_network"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  address_space = ["42.0.0.0/16"]
}

#resource "azurerm_subnet" "private" {
#  name = "aj_databricks_private_subnet"
#
#  resource_group_name  = "${var.resource_group_name}"
#  virtual_network_name = azurerm_virtual_network.this.name
#  address_prefixes     = ["42.0.0.0/24"]
#
#  delegation {
#    name = "databricks-delegation"
#
#    service_delegation {
#      name = "Microsoft.Databricks/workspaces"
#      actions = [
#        "Microsoft.Network/virtualNetworks/subnets/join/action",
#        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
#        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
#      ]
#    }
#  }
#}

resource "azurerm_subnet" "private" {
  for_each=var.private_subnets
  name = each.value["name"]

  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value["address_prefixes"]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "public" {
  for_each=var.public_subnets
  name = each.value["name"]

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value["address_prefixes"]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

#
#resource "azurerm_subnet" "public" {
#  name = "aj_databricks_public_subnet"
#
#  resource_group_name  = "${var.resource_group_name}"
#  virtual_network_name = azurerm_virtual_network.this.name
#  address_prefixes     = ["42.0.1.0/24"]
#
#  delegation {
#    name = "databricks-delegation"
#
#    service_delegation {
#      name = "Microsoft.Databricks/workspaces"
#      actions = [
#        "Microsoft.Network/virtualNetworks/subnets/join/action",
#        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
#        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
#      ]
#    }
#  }
#}
