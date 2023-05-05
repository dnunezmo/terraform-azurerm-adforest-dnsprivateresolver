#----------------------------------------------------------
# VNet, Subnet selection & Random Resources
#----------------------------------------------------------

resource "azurerm_virtual_network" "app_spoke_vnet" {
  name                = var.app_spoke_virtual_network_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.app_rg.name
  address_space       = ["192.168.0.0/16"]
}

# resource "azurerm_virtual_network_dns_servers" "app_spoke_dns" {
#   virtual_network_id = azurerm_virtual_network.app_spoke_vnet.id
#   dns_servers        = var.core_hub_private_ip_address
# }

resource "azurerm_subnet" "app_spoke_snet" {
  name                 = var.app_spoke_subnet_name
  virtual_network_name = azurerm_virtual_network.app_spoke_vnet.name
  resource_group_name  = azurerm_resource_group.app_rg.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "app_spoke_private_endpoint_snet" {
  name                 = var.app_spoke_private_endpoint_subnet_name
  virtual_network_name = azurerm_virtual_network.app_spoke_vnet.name
  resource_group_name  = azurerm_resource_group.app_rg.name
  address_prefixes     = ["192.168.1.0/24"]
}
