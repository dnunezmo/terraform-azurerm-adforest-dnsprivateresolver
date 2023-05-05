
#----------------------------------------------------------
# VNet, Subnet selection & Random Resources
#----------------------------------------------------------


resource "azurerm_virtual_network" "core_hub_vnet" {
  name                = var.core_hub_virtual_network_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network_dns_servers" "core_hub_dns" {
  virtual_network_id = azurerm_virtual_network.core_hub_vnet.id
  dns_servers        = var.core_hub_private_ip_address
}

resource "azurerm_subnet" "core_hub_snet" {
  name                 = var.core_hub_subnet_name
  virtual_network_name = azurerm_virtual_network.core_hub_vnet.name
  resource_group_name  = azurerm_resource_group.core_hub_rg.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "private-endpoint-snet" {
  name                 = var.core_hub_private_endpoint_subnet_name
  virtual_network_name = azurerm_virtual_network.core_hub_vnet.name
  resource_group_name  = azurerm_resource_group.core_hub_rg.name
  address_prefixes     = ["10.0.199.0/24"]
}

resource "azurerm_subnet" "inbound-endpoint-snet" {
  name                 = var.core_hub_inbound_subnet_name
  virtual_network_name = azurerm_virtual_network.core_hub_vnet.name
  resource_group_name  = azurerm_resource_group.core_hub_rg.name
  address_prefixes     = ["10.0.254.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "outbound-endpoint-snet" {
  name                 = var.core_hub_outbound_subnet_name
  virtual_network_name = azurerm_virtual_network.core_hub_vnet.name
  resource_group_name  = azurerm_resource_group.core_hub_rg.name
  address_prefixes     = ["10.0.253.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}


