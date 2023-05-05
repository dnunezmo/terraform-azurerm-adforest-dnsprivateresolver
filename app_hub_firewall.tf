resource "azurerm_public_ip" "app_hub_firewall_ip" {
  name                = "app-hub-firewall-ip"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "app_hub_firewall" {
  name                = "app-hub-firewall"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  private_ip_ranges = ["10.0.0.0/8"]

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.app_hub_azure_firewall_snet.id
    public_ip_address_id = azurerm_public_ip.app_hub_firewall_ip.id
  }
}