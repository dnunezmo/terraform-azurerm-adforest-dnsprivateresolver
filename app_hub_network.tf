#----------------------------------------------------------
# VNet, Subnet selection & Random Resources
#----------------------------------------------------------

resource "azurerm_virtual_network" "app_hub_vnet" {
  name                = var.app_hub_virtual_network_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.app_rg.name
  address_space       = ["10.1.0.0/16"]
}

# This is not needed as this vnet will use the default dns server
# resource "azurerm_virtual_network_dns_servers" "app_hub_dns" {
#   virtual_network_id = azurerm_virtual_network.app_hub_vnet.id
#   dns_servers        = azurerm_firewall.app_hub_firewall.ip_configuration.*.private_ip_address
# }

resource "azurerm_subnet" "app_hub_snet" {
  name                 = var.app_hub_subnet_name
  virtual_network_name = azurerm_virtual_network.app_hub_vnet.name
  resource_group_name  = azurerm_resource_group.app_rg.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "app_hub_azure_firewall_snet" {
  name                 = var.app_hub_azure_firewall_subnet_name
  virtual_network_name = azurerm_virtual_network.app_hub_vnet.name
  resource_group_name  = azurerm_resource_group.app_rg.name
  address_prefixes     = ["10.1.254.0/24"]
}
