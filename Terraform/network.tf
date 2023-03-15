resource "azurerm_virtual_network" "this" {
  name = "aj_databricks_virtual_network"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  address_space = ["42.0.0.0/16"]
}

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
#resource "azurerm_network_security_group" "example" {
#  name                = "network_security_group"
#  location            = var.location
#  resource_group_name = var.resource_group_name
#
#  security_rule {
#    name                       = "security_rule"
#    priority                   = 100
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "*"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }
#}

#resource "azurerm_subnet_network_security_group_association" "example" {
#  subnet_id                 = azurerm_subnet.example.id
#  network_security_group_id = azurerm_network_security_group.example.id
#}
#
#resource "azurerm_network_security_group" "nsg" {
#    name = "${var.dbname}-qa-databricks-nsg"
#    resource_group_name = data.azurerm_resource_group.qa.name
#    location= data.azurerm_resource_group.qa.location
#}
#
#resource "azurerm_subnet_network_security_group_association" "nsga_public" {
#    network_security_group_id = azurerm_network_security_group.nsg.id
#    subnet_id = azurerm_subnet.public.id
#}