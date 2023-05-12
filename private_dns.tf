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
  depends_on = [ azurerm_subnet.inbound-endpoint-snet ]
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outbound_endpoint" {
  name                    = "contoso-droe"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver.id
  location                = azurerm_private_dns_resolver.dns_resolver.location
  subnet_id               = azurerm_subnet.outbound-endpoint-snet.id
  depends_on = [ azurerm_subnet.outbound-endpoint-snet ]
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "ruleset" {
  name                                       = "ruleset"
  resource_group_name                        = azurerm_resource_group.core_hub_rg.name
  location                                   = azurerm_resource_group.core_hub_rg.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "onprem-rule" {
  name                      = "onprem-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "${var.onprem_active_directory_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = var.onprem_private_ip_address.0
    port       = 53
  }
  metadata = {
    key = "value"
  }
}

resource "azurerm_private_dns_resolver_forwarding_rule" "contoso-rule" {
  name                      = "azure-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "${var.core_hub_active_directory_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = var.core_hub_private_ip_address.0
    port       = 53
  }
  metadata = {
    key = "value"
  }
}

resource "azurerm_private_dns_resolver_forwarding_rule" "spoke1-rule" {
  name                      = "spoke1-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "spoke1.azure.contosodnslab.com."
  enabled                   = true
  target_dns_servers {
    ip_address = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint.ip_configurations.0.private_ip_address
    port       = 53
  }
  metadata = {
    key = "value"
  }
}

# For testing purposes we add the spoke2 rule to the same DNS forwarding ruleset as spoke1
resource "azurerm_private_dns_resolver_forwarding_rule" "spoke2-rule" {
  name                      = "spoke2-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  domain_name               = "spoke2.azure.contosodnslab.com."
  enabled                   = true
  target_dns_servers {
    ip_address = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint.ip_configurations.0.private_ip_address
    port       = 53
  }
  metadata = {
    key = "value"
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "app-hub-link" {
  name                      = "app-hub-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
  virtual_network_id        = azurerm_virtual_network.app_hub_vnet.id
}

# This link is not needed as the spoke will use azure firewall for DNS resolution
# resource "azurerm_private_dns_resolver_virtual_network_link" "app-spoke-link" {
#   name                      = "app-spoke-link"
#   dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset.id
#   virtual_network_id        = azurerm_virtual_network.app_spoke_vnet.id
# }

#---------------------------------------
# Private DNS Zone for Blob Storage in the control plane hub
#---------------------------------------

resource "azurerm_private_dns_zone" "routable-blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.core_hub_rg.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "routable-blob-link" {
  name                  = "core-hub-vnet-blob-link"
  resource_group_name   = azurerm_resource_group.core_hub_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.routable-blob.name
  virtual_network_id    = azurerm_virtual_network.core_hub_vnet.id
}

#---------------------------------------
# Private DNS Zone for Blob Storage in the app hub
#---------------------------------------

resource "azurerm_private_dns_zone" "nonroutable-blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.app_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "nonroutable-blob-link" {
  name                  = "app-hub-vnet-blob-link"
  resource_group_name   = azurerm_resource_group.app_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.nonroutable-blob.name
  virtual_network_id    = azurerm_virtual_network.app_hub_vnet.id
}

#---------------------------------------
# Private DNS Zone for Non Routable Network spoke1.azure.contosodnslab.com
#---------------------------------------

resource "azurerm_private_dns_zone" "spoke-nonroutable" {
  name                = "spoke1.azure.contosodnslab.com"
  resource_group_name = azurerm_resource_group.app_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke1-app-hub-link" {
  name                  = "spoke1-app-hub-link"
  resource_group_name   = azurerm_resource_group.app_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.spoke-routable.name
  virtual_network_id    = azurerm_virtual_network.app_hub_vnet.id
  registration_enabled = false
}

# Optional: Create a virtual network link to the Private DNS Zone in the non-routable spoke, to allow automatic registration of VMs in the spoke
resource "azurerm_private_dns_zone_virtual_network_link" "spoke1-app-spoke-link" {
  name                  = "spoke1-app-spoke-link"
  resource_group_name   = azurerm_resource_group.app_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.spoke-nonroutable.name
  virtual_network_id    = azurerm_virtual_network.app_spoke_vnet.id
  registration_enabled = true
}

#---------------------------------------
# Private DNS Zone for Routable Network spoke1.azure.contosodnslab.com
#---------------------------------------

resource "azurerm_private_dns_zone" "spoke-routable" {
  name                = "spoke1.azure.contosodnslab.com"
  resource_group_name = azurerm_resource_group.core_hub_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke1-core-hub-link" {
  name                  = "spoke1-core-hub-link"
  resource_group_name   = azurerm_resource_group.core_hub_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.spoke-routable.name
  virtual_network_id    = azurerm_virtual_network.core_hub_vnet.id
  registration_enabled = false
}

# Create DNS A Record
resource "azurerm_private_dns_a_record" "spoke-routable-dns_a" {
  count                         = var.app_spoke_instances_count
  name                = azurerm_windows_virtual_machine.app_spoke_win_vm.0.name
  zone_name           = azurerm_private_dns_zone.spoke-routable.name
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  ttl                 = 300
  records             = ["10.1.0.99"]
}

# This block is not needed as the app hub will use DNS private resolver for DNS resolution
# resource "azurerm_private_dns_zone_virtual_network_link" "spoke-app-hub-link" {
#   name                  = "spoke1-app-hub-link"
#   resource_group_name   = azurerm_resource_group.app_rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.spoke-routable.name
#   virtual_network_id    = azurerm_virtual_network.app_hub_vnet.id
#   registration_enabled = false
# }


#---------------------------------------
# Private DNS Zone for Routable Network spoke2.azure.contosodnslab.com
#---------------------------------------

resource "azurerm_private_dns_zone" "spoke2-routable" {
  name                = "spoke2.azure.contosodnslab.com"
  resource_group_name = azurerm_resource_group.core_hub_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke2-core-hub-link" {
  name                  = "spoke2-core-hub-link"
  resource_group_name   = azurerm_resource_group.core_hub_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.spoke2-routable.name
  virtual_network_id    = azurerm_virtual_network.core_hub_vnet.id
  registration_enabled = false
}

# Create DNS A Record
resource "azurerm_private_dns_a_record" "spoke2-routable-dns_a" {
  count               = var.app_spoke_instances_count
  name                = "spoke2-vm"
  zone_name           = azurerm_private_dns_zone.spoke2-routable.name
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  ttl                 = 300
  records             = ["10.2.0.99"]
}
