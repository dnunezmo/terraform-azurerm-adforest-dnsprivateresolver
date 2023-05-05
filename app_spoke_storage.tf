#---------------------------------------
# Storage Account
#---------------------------------------

resource "azurerm_storage_account" "storage" {
  name                     = "contosostg01"
  resource_group_name      = azurerm_resource_group.app_rg.name
  location                 = azurerm_resource_group.app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "storage" {
  name                = "contoso-stg-01-endpoint"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.private-endpoint-snet.id

  private_service_connection {
    name                           = "contoso-stg-01-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}
