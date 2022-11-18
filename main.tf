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
  azure_password_command        = "$password = ConvertTo-SecureString ${var.azure_admin_password == null ? element(concat(random_password.azure_passwd.*.result, [""]), 0) : var.azure_admin_password} -AsPlainText -Force"
  azure_configure_ad_command    = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.azure_active_directory_domain} -DomainNetbiosName ${var.azure_active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  configure_dns_command         = "Add-DnsServerForwarder -IPAddress 168.63.129.16 -PassThru"
  onprem_configure_dns_command  = "Add-DnsServerConditionalForwarderZone -Name ${var.azure_active_directory_domain} -MasterServers ${var.azure_private_ip_address.0} -PassThru"
  onprem_configure_dns_command2 = "Add-DnsServerConditionalForwarderZone -Name 'blob.core.windows.net' -MasterServers ${var.azure_private_ip_address.0} -PassThru"
  azure_configure_dns_command   = "Add-DnsServerConditionalForwarderZone -Name ${var.onprem_active_directory_domain} -MasterServers ${var.onprem_private_ip_address.0} -PassThru"
  shutdown_command              = "shutdown -r -t 60"
  exit_code_hack                = "exit 0"
  onprem_powershell_command     = "${local.import_command}; ${local.onprem_password_command}; ${local.install_ad_command}; ${local.onprem_configure_ad_command}; ${local.configure_dns_command}; ${local.onprem_configure_dns_command}; ${local.onprem_configure_dns_command2}; ${local.shutdown_command}; ${local.exit_code_hack}"
  azure_powershell_command      = "${local.import_command}; ${local.azure_password_command}; ${local.install_ad_command}; ${local.azure_configure_ad_command}; ${local.configure_dns_command}; ${local.azure_configure_dns_command}; ${local.shutdown_command}; ${local.exit_code_hack}"

}

#----------------------------------------------------------
# Onpremises Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
resource "azurerm_resource_group" "onprem_rg" {
  name     = var.onprem_resource_group_name
  location = "West Europe"
}

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

resource "random_password" "onprem_passwd" {
  count       = var.onprem_os_flavor == "windows" && var.onprem_admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.onprem_os_flavor
  }
}

resource "random_string" "onprem_str" {
  count   = var.enable_public_ip_address == true ? var.onprem_instances_count : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.onprem_virtual_machine_name
  }
}

#---------------------------------------
# VNet Peerings
#---------------------------------------

resource "azurerm_virtual_network_peering" "onprem" {
  name                      = "onprem-to-contoso"
  resource_group_name       = azurerm_resource_group.onprem_rg.name
  virtual_network_name      = azurerm_virtual_network.onprem_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.azure_vnet.id
}

resource "azurerm_virtual_network_peering" "contoso" {
  name                      = "contoso-to-onprem"
  resource_group_name       = "contoso-hub-001"
  virtual_network_name      = "contoso-vnet"
  remote_virtual_network_id = azurerm_virtual_network.onprem_vnet.id
}

#-----------------------------------
# Onpremises Public IP for Virtual Machine
#-----------------------------------
resource "azurerm_public_ip" "onprem_pip" {
  count               = var.enable_public_ip_address == true ? var.onprem_instances_count : 0
  name                = lower("pip-vm-${var.onprem_virtual_machine_name}-${azurerm_resource_group.onprem_rg.location}-0${count.index + 1}")
  location            = azurerm_resource_group.onprem_rg.location
  resource_group_name = azurerm_resource_group.onprem_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.onprem_str[count.index].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.onprem_virtual_machine_name}-${azurerm_resource_group.onprem_rg.location}-0${count.index + 1}") }, var.tags, )
}

#---------------------------------------
# Onpremises Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "onprem_nic" {
  count                         = var.onprem_instances_count
  name                          = var.onprem_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = azurerm_resource_group.onprem_rg.name
  location                      = azurerm_resource_group.onprem_rg.location
  dns_servers                   = var.onprem_dns_servers
  enable_ip_forwarding          = var.onprem_enable_ip_forwarding
  enable_accelerated_networking = var.onprem_enable_accelerated_networking
  tags                          = merge({ "ResourceName" = var.onprem_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = azurerm_subnet.onprem_snet.id
    private_ip_address_allocation = var.onprem_private_ip_address_allocation_type
    private_ip_address            = var.onprem_private_ip_address_allocation_type == "Static" ? element(concat(var.onprem_private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.onprem_pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "onprem_aset" {
  count                        = var.onprem_enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.onprem_virtual_machine_name}-${azurerm_resource_group.onprem_rg.location}")
  resource_group_name          = azurerm_resource_group.onprem_rg.name
  location                     = azurerm_resource_group.onprem_rg.location
  platform_fault_domain_count  = var.onprem_platform_fault_domain_count
  platform_update_domain_count = var.onprem_platform_update_domain_count
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.onprem_virtual_machine_name}-${azurerm_resource_group.onprem_rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Onpremises Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "onprem_nsg" {
  name                = lower("nsg_${var.onprem_virtual_machine_name}_${azurerm_resource_group.onprem_rg.location}_in")
  resource_group_name = azurerm_resource_group.onprem_rg.name
  location            = azurerm_resource_group.onprem_rg.location
  tags                = merge({ "ResourceName" = lower("nsg_${var.onprem_virtual_machine_name}_${azurerm_resource_group.onprem_rg.location}_in") }, var.tags, )
}

resource "azurerm_network_security_rule" "onprem_nsg_rule" {
  for_each                    = local.nsg_inbound_rules
  name                        = each.key
  priority                    = 100 * (each.value.idx + 1)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.security_rule.destination_port_range
  source_address_prefix       = each.value.security_rule.source_address_prefix
  destination_address_prefix  = element(concat(azurerm_subnet.onprem_snet.address_prefixes, [""]), 0)
  description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
  resource_group_name         = azurerm_resource_group.onprem_rg.name
  network_security_group_name = azurerm_network_security_group.onprem_nsg.name
  depends_on                  = [azurerm_network_security_group.onprem_nsg]
}

resource "azurerm_network_interface_security_group_association" "onprem_nsgassoc" {
  count                     = var.onprem_instances_count
  network_interface_id      = element(concat(azurerm_network_interface.onprem_nic.*.id, [""]), count.index)
  network_security_group_id = azurerm_network_security_group.onprem_nsg.id
}

#---------------------------------------
# Onpremises Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "onprem_win_vm" {
  count                      = var.onprem_os_flavor == "windows" ? var.onprem_instances_count : 0
  name                       = var.onprem_instances_count == 1 ? var.onprem_virtual_machine_name : format("%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = var.onprem_instances_count == 1 ? var.onprem_virtual_machine_name : format("%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) # not more than 15 characters
  resource_group_name        = azurerm_resource_group.onprem_rg.name
  location                   = azurerm_resource_group.onprem_rg.location
  size                       = var.onprem_virtual_machine_size
  admin_username             = var.onprem_admin_username
  admin_password             = var.onprem_admin_password == null ? element(concat(random_password.onprem_passwd.*.result, [""]), 0) : var.onprem_admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.onprem_nic.*.id, [""]), count.index)]
  source_image_id            = var.onprem_source_image_id != null ? var.onprem_source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.onprem_dedicated_host_id
  license_type               = var.onprem_license_type
  availability_set_id        = var.onprem_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.onprem_aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = var.onprem_instances_count == 1 ? var.onprem_virtual_machine_name : format("%s%s", lower(replace(var.onprem_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  dynamic "source_image_reference" {
    for_each = var.onprem_source_image_id != null ? [] : [1]
    content {
      publisher = var.onprem_windows_distribution_list[lower(var.onprem_windows_distribution_name)]["publisher"]
      offer     = var.onprem_windows_distribution_list[lower(var.onprem_windows_distribution_name)]["offer"]
      sku       = var.onprem_windows_distribution_list[lower(var.onprem_windows_distribution_name)]["sku"]
      version   = var.onprem_windows_distribution_list[lower(var.onprem_windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.onprem_os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#---------------------------------------
# Onpremises Promote Domain Controller
#---------------------------------------
resource "azurerm_virtual_machine_extension" "onprem_adforest" {
  name                       = "ad-forest-creation"
  virtual_machine_id         = azurerm_windows_virtual_machine.onprem_win_vm.0.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.onprem_powershell_command}\""
    }
SETTINGS
}





#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
resource "azurerm_resource_group" "azure_rg" {
  name     = var.azure_resource_group_name
  location = "West Europe"
}

resource "azurerm_virtual_network" "azure_vnet" {
  name                = var.azure_virtual_network_name
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.azure_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network_dns_servers" "azure_dns" {
  virtual_network_id = azurerm_virtual_network.azure_vnet.id
  dns_servers        = var.azure_private_ip_address
}
resource "azurerm_subnet" "azure_snet" {
  name                 = var.azure_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
  address_prefixes     = ["10.0.0.0/24"]
}


resource "azurerm_subnet" "private-endpoint-snet" {
  name                 = var.azure_private_endpoint_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
  address_prefixes     = ["10.0.199.0/24"]
}

resource "azurerm_subnet" "inbound-endpoint-snet" {
  name                 = var.azure_inbound_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
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
  name                 = var.azure_outbound_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
  address_prefixes     = ["10.0.253.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "random_password" "azure_passwd" {
  count       = var.azure_os_flavor == "windows" && var.azure_admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.azure_os_flavor
  }
}

resource "random_string" "azure_str" {
  count   = var.enable_public_ip_address == true ? var.azure_instances_count : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.azure_virtual_machine_name
  }
}

#-----------------------------------
# Public IP for Virtual Machine
#-----------------------------------
resource "azurerm_public_ip" "azure_pip" {
  count               = var.enable_public_ip_address == true ? var.azure_instances_count : 0
  name                = lower("pip-vm-${var.azure_virtual_machine_name}-${azurerm_resource_group.azure_rg.location}-0${count.index + 1}")
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.azure_str[count.index].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.azure_virtual_machine_name}-${azurerm_resource_group.azure_rg.location}-0${count.index + 1}") }, var.tags, )
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "azure_nic" {
  count                         = var.azure_instances_count
  name                          = var.azure_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = azurerm_resource_group.azure_rg.name
  location                      = azurerm_resource_group.azure_rg.location
  dns_servers                   = var.azure_dns_servers
  enable_ip_forwarding          = var.azure_enable_ip_forwarding
  enable_accelerated_networking = var.azure_enable_accelerated_networking
  tags                          = merge({ "ResourceName" = var.azure_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = azurerm_subnet.azure_snet.id
    private_ip_address_allocation = var.azure_private_ip_address_allocation_type
    private_ip_address            = var.azure_private_ip_address_allocation_type == "Static" ? element(concat(var.azure_private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.azure_pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "azure_aset" {
  count                        = var.azure_enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.azure_virtual_machine_name}-${azurerm_resource_group.azure_rg.location}")
  resource_group_name          = azurerm_resource_group.azure_rg.name
  location                     = azurerm_resource_group.azure_rg.location
  platform_fault_domain_count  = var.azure_platform_fault_domain_count
  platform_update_domain_count = var.azure_platform_update_domain_count
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.azure_virtual_machine_name}-${azurerm_resource_group.azure_rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "azure_nsg" {
  name                = lower("nsg_${var.azure_virtual_machine_name}_${azurerm_resource_group.azure_rg.location}_in")
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  tags                = merge({ "ResourceName" = lower("nsg_${var.azure_virtual_machine_name}_${azurerm_resource_group.azure_rg.location}_in") }, var.tags, )
}

resource "azurerm_network_security_rule" "azure_nsg_rule" {
  for_each                    = local.nsg_inbound_rules
  name                        = each.key
  priority                    = 100 * (each.value.idx + 1)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.security_rule.destination_port_range
  source_address_prefix       = each.value.security_rule.source_address_prefix
  destination_address_prefix  = element(concat(azurerm_subnet.azure_snet.address_prefixes, [""]), 0)
  description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
  resource_group_name         = azurerm_resource_group.azure_rg.name
  network_security_group_name = azurerm_network_security_group.azure_nsg.name
  depends_on                  = [azurerm_network_security_group.azure_nsg]
}

resource "azurerm_network_interface_security_group_association" "azure_nsgassoc" {
  count                     = var.azure_instances_count
  network_interface_id      = element(concat(azurerm_network_interface.azure_nic.*.id, [""]), count.index)
  network_security_group_id = azurerm_network_security_group.azure_nsg.id
}

#---------------------------------------
# Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "azure_win_vm" {
  count                      = var.azure_os_flavor == "windows" ? var.azure_instances_count : 0
  name                       = var.azure_instances_count == 1 ? var.azure_virtual_machine_name : format("%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = var.azure_instances_count == 1 ? var.azure_virtual_machine_name : format("%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) # not more than 15 characters
  resource_group_name        = azurerm_resource_group.azure_rg.name
  location                   = azurerm_resource_group.azure_rg.location
  size                       = var.azure_virtual_machine_size
  admin_username             = var.azure_admin_username
  admin_password             = var.azure_admin_password == null ? element(concat(random_password.azure_passwd.*.result, [""]), 0) : var.azure_admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.azure_nic.*.id, [""]), count.index)]
  source_image_id            = var.azure_source_image_id != null ? var.azure_source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.azure_dedicated_host_id
  license_type               = var.azure_license_type
  availability_set_id        = var.azure_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.azure_aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = var.azure_instances_count == 1 ? var.azure_virtual_machine_name : format("%s%s", lower(replace(var.azure_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  dynamic "source_image_reference" {
    for_each = var.azure_source_image_id != null ? [] : [1]
    content {
      publisher = var.azure_windows_distribution_list[lower(var.azure_windows_distribution_name)]["publisher"]
      offer     = var.azure_windows_distribution_list[lower(var.azure_windows_distribution_name)]["offer"]
      sku       = var.azure_windows_distribution_list[lower(var.azure_windows_distribution_name)]["sku"]
      version   = var.azure_windows_distribution_list[lower(var.azure_windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.azure_os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#---------------------------------------
# Promote Domain Controller
#---------------------------------------
resource "azurerm_virtual_machine_extension" "azure_adforest" {
  name                       = "ad-forest-creation"
  virtual_machine_id         = azurerm_windows_virtual_machine.azure_win_vm.0.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.azure_powershell_command}\""
    }
SETTINGS
}

#---------------------------------------
# Private DNS Resolver
#---------------------------------------
resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = "contoso-dns-resolver"
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  virtual_network_id  = azurerm_virtual_network.azure_vnet.id
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
  resource_group_name                        = azurerm_resource_group.azure_rg.name
  location                                   = azurerm_resource_group.azure_rg.location
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
  virtual_network_id        = azurerm_virtual_network.azure_vnet.id
}

#---------------------------------------
# Private DNS Zone for Blob Storage
#---------------------------------------

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.azure_rg.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "blob-link" {
  name                  = "contoso-vnet-blob-link"
  resource_group_name   = azurerm_resource_group.azure_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.azure_vnet.id
}


# Create DNS A Record
resource "azurerm_private_dns_a_record" "dns_a" {
  name                = "contosostg01"
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.azure_rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage.private_service_connection.0.private_ip_address]
}

#---------------------------------------
# Storage Account
#---------------------------------------

resource "azurerm_storage_account" "storage" {
  name                     = "contosostg01"
  resource_group_name      = azurerm_resource_group.azure_rg.name
  location                 = azurerm_resource_group.azure_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "storage" {
  name                = "contoso-stg-01-endpoint"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  subnet_id           = azurerm_subnet.private-endpoint-snet.id

  private_service_connection {
    name                           = "contoso-stg-01-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}
