#---------------------------------------
# Private DNS Resolver
#---------------------------------------
resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = "contoso-dns-resolver"
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  location            = azurerm_resource_group.core_hub_rg.location
  virtual_network_id  = azurerm_virtual_network.core_hub_vnet.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound_endpoint" {
  name                    = "contoso-drie"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver.id
  location                = azurerm_private_dns_resolver.dns_resolver.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.inbound-endpoint-snet.id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outbound_endpoint" {
  name                    = "contoso-droe"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver.id
  location                = azurerm_private_dns_resolver.dns_resolver.location
  subnet_id               = azurerm_subnet.outbound-endpoint-snet.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "ruleset" {
  name                                       = "contoso-ruleset"
  resource_group_name                        = azurerm_resource_group.core_hub_rg.name
  location                                   = azurerm_resource_group.core_hub_rg.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "dns-rule" {
  name                      = "contoso-rule-onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "onprem.com."
  enabled                   = true
  target_dns_servers {
    ip_address = "10.8.0.4"
    port       = 53
  }
  metadata = {
    key = "value"
  }
}

resource "azurerm_private_dns_resolver_forwarding_rule" "dns-rule2" {
  name                      = "contoso-rule-contoso"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "contoso.com."
  enabled                   = true
  target_dns_servers {
    ip_address = "10.0.0.4"
    port       = 53
  }
  metadata = {
    key = "value"
  }
}


resource "azurerm_private_dns_resolver_virtual_network_link" "dns-link" {
  name                      = "contoso-dns-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  virtual_network_id        = azurerm_virtual_network.core_hub_vnet.id
}

#---------------------------------------
# Private DNS Zone for Blob Storage
#---------------------------------------

# resource "azurerm_private_dns_zone" "blob" {
#   name                = "privatelink.blob.core.windows.net"
#   resource_group_name = azurerm_resource_group.core_hub_rg.name
# }


# resource "azurerm_private_dns_zone_virtual_network_link" "blob-link" {
#   name                  = "contoso-vnet-blob-link"
#   resource_group_name   = azurerm_resource_group.core_hub_rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.blob.name
#   virtual_network_id    = azurerm_virtual_network.core_hub_vnet.id
# }


# # Create DNS A Record
# resource "azurerm_private_dns_a_record" "dns_a" {
#   name                = "contosostg01"
#   zone_name           = azurerm_private_dns_zone.blob.name
#   resource_group_name = azurerm_resource_group.core_hub_rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.storage.private_service_connection.0.private_ip_address]
# }
