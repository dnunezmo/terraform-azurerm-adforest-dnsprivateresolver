#----------------------------------------------------------
# Onpremises VNet, Subnet selection & Random Resources
#----------------------------------------------------------

resource "azurerm_virtual_network" "onprem_vnet" {
  name                = var.onprem_virtual_network_name
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.onprem_rg.name
  address_space       = ["10.8.0.0/16"]
}

resource "azurerm_virtual_network_dns_servers" "onprem_dns" {
  virtual_network_id = azurerm_virtual_network.onprem_vnet.id
  dns_servers        = var.onprem_private_ip_address
}

resource "azurerm_subnet" "onprem_snet" {
  name                 = var.onprem_subnet_name
  virtual_network_name = azurerm_virtual_network.onprem_vnet.name
  resource_group_name  = azurerm_resource_group.onprem_rg.name
  address_prefixes     = ["10.8.0.0/24"]
}
