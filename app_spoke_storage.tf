#---------------------------------------
# Storage Account
#---------------------------------------

resource "azurerm_storage_account" "storage" {
  name                     = "contosostg01"
  resource_group_name      = azurerm_resource_group.app_rg.name
  location                 = azurerm_resource_group.app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public   = false
}

resource "azurerm_private_endpoint" "storage-routable-endpoint" {
  name                = "contoso-stg-01-routable-endpoint"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.private-endpoint-snet.id

  private_service_connection {
    name                           = "contoso-stg-01-routable-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# Create DNS A Record
resource "azurerm_private_dns_a_record" "routable-blob-dns_a" {
  name                = "contosostg01"
  zone_name           = azurerm_private_dns_zone.routable-blob.name
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage-routable-endpoint.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_endpoint" "storage-nonroutable-endpoint" {
  name                = "contoso-stg-01-nonroutable-endpoint"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.app_spoke_private_endpoint_snet.id

  private_service_connection {
    name                           = "contoso-stg-01-nonroutable-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# Create DNS A Record
resource "azurerm_private_dns_a_record" "nonroutable-blob-dns_a" {
  name                = "contosostg01"
  zone_name           = azurerm_private_dns_zone.nonroutable-blob.name
  resource_group_name = azurerm_resource_group.app_rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage-nonroutable-endpoint.private_service_connection.0.private_ip_address]
}
