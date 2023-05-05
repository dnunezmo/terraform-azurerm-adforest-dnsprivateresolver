#-------------------------------
# Local Declarations
#-------------------------------
locals {
  nsg_inbound_rules = { for idx, security_rule in var.nsg_inbound_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
    }
  }

  import_command                = "Import-Module ADDSDeployment"
  onprem_password_command       = "$password = ConvertTo-SecureString ${var.onprem_admin_password == null ? element(concat(random_password.onprem_passwd.*.result, [""]), 0) : var.onprem_admin_password} -AsPlainText -Force"
  install_ad_command            = "Install-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools"
  onprem_configure_ad_command   = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.onprem_active_directory_domain} -DomainNetbiosName ${var.onprem_active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  core_hub_password_command        = "$password = ConvertTo-SecureString ${var.core_hub_admin_password == null ? element(concat(random_password.core_hub_passwd.*.result, [""]), 0) : var.core_hub_admin_password} -AsPlainText -Force"
  core_hub_configure_ad_command    = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.core_hub_active_directory_domain} -DomainNetbiosName ${var.core_hub_active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  configure_dns_command         = "Add-DnsServerForwarder -IPAddress 168.63.129.16 -PassThru"
  onprem_configure_dns_command  = "Add-DnsServerConditionalForwarderZone -Name ${var.core_hub_active_directory_domain} -MasterServers ${var.core_hub_private_ip_address.0} -PassThru"
  onprem_configure_dns_command2 = "Add-DnsServerConditionalForwarderZone -Name 'blob.core.windows.net' -MasterServers ${var.core_hub_private_ip_address.0} -PassThru"
  core_hub_configure_dns_command   = "Add-DnsServerConditionalForwarderZone -Name ${var.onprem_active_directory_domain} -MasterServers ${var.onprem_private_ip_address.0} -PassThru"
  shutdown_command              = "shutdown -r -t 60"
  exit_code_hack                = "exit 0"
  onprem_powershell_command     = "${local.import_command}; ${local.onprem_password_command}; ${local.install_ad_command}; ${local.onprem_configure_ad_command}; ${local.configure_dns_command}; ${local.onprem_configure_dns_command}; ${local.onprem_configure_dns_command2}; ${local.shutdown_command}; ${local.exit_code_hack}"
  core_hub_powershell_command      = "${local.import_command}; ${local.core_hub_password_command}; ${local.install_ad_command}; ${local.core_hub_configure_ad_command}; ${local.configure_dns_command}; ${local.core_hub_configure_dns_command}; ${local.shutdown_command}; ${local.exit_code_hack}"

}

#---------------------------------------
# Resource Groups
#---------------------------------------

resource "azurerm_resource_group" "onprem_rg" {
  name     = var.onprem_resource_group_name
  location = var.onprem_location
}

resource "azurerm_resource_group" "core_hub_rg" {
  name     = var.core_hub_resource_group_name
  location = var.azure_location
}

resource "azurerm_resource_group" "app_rg" {
  name     = var.app_resource_group_name
  location = var.azure_location
}

#---------------------------------------
# VNet Peerings
#---------------------------------------

resource "azurerm_virtual_network_peering" "onprem_to_core_hub" {
  name                      = "onprem-to-core-hub"
  resource_group_name       = azurerm_resource_group.onprem_rg.name
  virtual_network_name      = azurerm_virtual_network.onprem_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.core_hub_vnet.id
}

resource "azurerm_virtual_network_peering" "core_hub_to_onprem" {
  name                      = "core-hub-to-onprem"
  resource_group_name       = azurerm_resource_group.core_hub_rg.name
  virtual_network_name      = azurerm_virtual_network.core_hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.onprem_vnet.id
}

resource "azurerm_virtual_network_peering" "app_hub_to_core_hub" {
  name                      = "app-hub-to-core-hub"
  resource_group_name       = azurerm_resource_group.app_rg.name
  virtual_network_name      = azurerm_virtual_network.app_hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.core_hub_vnet.id
}

resource "azurerm_virtual_network_peering" "core_hub_to_app_hub" {
  name                      = "core-hub-to-app-hub"
  resource_group_name       = azurerm_resource_group.core_hub_rg.name
  virtual_network_name      = azurerm_virtual_network.core_hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_hub_vnet.id
}


resource "azurerm_virtual_network_peering" "app_hub_to_app_spoke" {
  name                      = "app-hub-to-app-spoke"
  resource_group_name       = azurerm_resource_group.app_rg.name
  virtual_network_name      = azurerm_virtual_network.app_hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_spoke_vnet.id
}

resource "azurerm_virtual_network_peering" "app_spoke_to_app_hub" {
  name                      = "app-spoke-to-app-hub"
  resource_group_name       = azurerm_resource_group.app_rg.name
  virtual_network_name      = azurerm_virtual_network.app_spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_hub_vnet.id
}
