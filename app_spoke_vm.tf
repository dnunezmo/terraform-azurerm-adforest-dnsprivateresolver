resource "random_password" "app_spoke_passwd" {
  count       = var.app_spoke_os_flavor == "windows" && var.app_spoke_admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.app_spoke_os_flavor
  }
}

resource "random_string" "app_spoke_str" {
  count   = var.enable_public_ip_address == true ? var.app_spoke_instances_count : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.app_spoke_virtual_machine_name
  }
}
#-----------------------------------
# Public IP for Virtual Machine
#-----------------------------------
resource "azurerm_public_ip" "app_spoke_pip" {
  count               = var.enable_public_ip_address == true ? var.app_spoke_instances_count : 0
  name                = lower("pip-vm-${var.app_spoke_virtual_machine_name}-${azurerm_resource_group.app_rg.location}-0${count.index + 1}")
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.app_spoke_str[count.index].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.app_spoke_virtual_machine_name}-${azurerm_resource_group.app_rg.location}-0${count.index + 1}") }, var.tags, )
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "app_spoke_nic" {
  count                         = var.app_spoke_instances_count
  name                          = var.app_spoke_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = azurerm_resource_group.app_rg.name
  location                      = azurerm_resource_group.app_rg.location
  dns_servers                   = var.app_spoke_dns_servers
  enable_ip_forwarding          = var.app_spoke_enable_ip_forwarding
  enable_accelerated_networking = var.app_spoke_enable_accelerated_networking
  tags                          = merge({ "ResourceName" = var.app_spoke_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = azurerm_subnet.app_spoke_snet.id
    private_ip_address_allocation = var.app_spoke_private_ip_address_allocation_type
    private_ip_address            = var.app_spoke_private_ip_address_allocation_type == "Static" ? element(concat(var.app_spoke_private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.app_spoke_pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "app_spoke_aset" {
  count                        = var.app_spoke_enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.app_spoke_virtual_machine_name}-${azurerm_resource_group.app_rg.location}")
  resource_group_name          = azurerm_resource_group.app_rg.name
  location                     = azurerm_resource_group.app_rg.location
  platform_fault_domain_count  = var.app_spoke_platform_fault_domain_count
  platform_update_domain_count = var.app_spoke_platform_update_domain_count
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.app_spoke_virtual_machine_name}-${azurerm_resource_group.app_rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface - Commented since not needed in MCAPs subscription
#---------------------------------------------------------------
# resource "azurerm_network_security_group" "app_spoke_nsg" {
#   name                = lower("nsg_${var.app_spoke_virtual_machine_name}_${azurerm_resource_group.app_rg.location}_in")
#   resource_group_name = azurerm_resource_group.app_rg.name
#   location            = azurerm_resource_group.app_rg.location
#   tags                = merge({ "ResourceName" = lower("nsg_${var.app_spoke_virtual_machine_name}_${azurerm_resource_group.app_rg.location}_in") }, var.tags, )
# }

# resource "azurerm_network_security_rule" "app_spoke_nsg_rule" {
#   for_each                    = local.nsg_inbound_rules
#   name                        = each.key
#   priority                    = 100 * (each.value.idx + 1)
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = each.value.security_rule.destination_port_range
#   source_address_prefix       = each.value.security_rule.source_address_prefix
#   destination_address_prefix  = element(concat(azurerm_subnet.app_spoke_snet.address_prefixes, [""]), 0)
#   description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
#   resource_group_name         = azurerm_resource_group.app_rg.name
#   network_security_group_name = azurerm_network_security_group.app_spoke_nsg.name
#   depends_on                  = [azurerm_network_security_group.app_spoke_nsg]
# }

# resource "azurerm_network_interface_security_group_association" "app_spoke_nsgassoc" {
#   count                     = var.app_spoke_instances_count
#   network_interface_id      = element(concat(azurerm_network_interface.app_spoke_nic.*.id, [""]), count.index)
#   network_security_group_id = azurerm_network_security_group.app_spoke_nsg.id
# }

#---------------------------------------
# Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "app_spoke_win_vm" {
  count                      = var.app_spoke_os_flavor == "windows" ? var.app_spoke_instances_count : 0
  name                       = var.app_spoke_instances_count == 1 ? var.app_spoke_virtual_machine_name : format("%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = var.app_spoke_instances_count == 1 ? var.app_spoke_virtual_machine_name : format("%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) # not more than 15 characters
  resource_group_name        = azurerm_resource_group.app_rg.name
  location                   = azurerm_resource_group.app_rg.location
  size                       = var.app_spoke_virtual_machine_size
  admin_username             = var.app_spoke_admin_username
  admin_password             = var.app_spoke_admin_password == null ? element(concat(random_password.app_spoke_passwd.*.result, [""]), 0) : var.app_spoke_admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.app_spoke_nic.*.id, [""]), count.index)]
  source_image_id            = var.app_spoke_source_image_id != null ? var.app_spoke_source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.app_spoke_dedicated_host_id
  license_type               = var.app_spoke_license_type
  availability_set_id        = var.app_spoke_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.app_spoke_aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = var.app_spoke_instances_count == 1 ? var.app_spoke_virtual_machine_name : format("%s%s", lower(replace(var.app_spoke_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  dynamic "source_image_reference" {
    for_each = var.app_spoke_source_image_id != null ? [] : [1]
    content {
      publisher = var.app_spoke_windows_distribution_list[lower(var.app_spoke_windows_distribution_name)]["publisher"]
      offer     = var.app_spoke_windows_distribution_list[lower(var.app_spoke_windows_distribution_name)]["offer"]
      sku       = var.app_spoke_windows_distribution_list[lower(var.app_spoke_windows_distribution_name)]["sku"]
      version   = var.app_spoke_windows_distribution_list[lower(var.app_spoke_windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.app_spoke_os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}
