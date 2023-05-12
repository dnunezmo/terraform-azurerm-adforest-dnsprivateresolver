resource "random_password" "core_hub_passwd" {
  count       = var.core_hub_os_flavor == "windows" && var.core_hub_admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.core_hub_os_flavor
  }
}

resource "random_string" "core_hub_str" {
  count   = var.enable_public_ip_address == true ? var.core_hub_instances_count : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.core_hub_virtual_machine_name
  }
}
#-----------------------------------
# Public IP for Virtual Machine
#-----------------------------------
resource "azurerm_public_ip" "core_hub_pip" {
  count               = var.enable_public_ip_address == true ? var.core_hub_instances_count : 0
  name                = lower("pip-vm-${var.core_hub_virtual_machine_name}-${azurerm_resource_group.core_hub_rg.location}-0${count.index + 1}")
  location            = azurerm_resource_group.core_hub_rg.location
  resource_group_name = azurerm_resource_group.core_hub_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.core_hub_str[count.index].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.core_hub_virtual_machine_name}-${azurerm_resource_group.core_hub_rg.location}-0${count.index + 1}") }, var.tags, )
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "core_hub_nic" {
  count                         = var.core_hub_instances_count
  name                          = var.core_hub_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = azurerm_resource_group.core_hub_rg.name
  location                      = azurerm_resource_group.core_hub_rg.location
  dns_servers                   = var.core_hub_dns_servers
  enable_ip_forwarding          = var.core_hub_enable_ip_forwarding
  enable_accelerated_networking = var.core_hub_enable_accelerated_networking
  tags                          = merge({ "ResourceName" = var.core_hub_instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = azurerm_subnet.core_hub_snet.id
    private_ip_address_allocation = var.core_hub_private_ip_address_allocation_type
    private_ip_address            = var.core_hub_private_ip_address_allocation_type == "Static" ? element(concat(var.core_hub_private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.core_hub_pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "core_hub_aset" {
  count                        = var.core_hub_enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.core_hub_virtual_machine_name}-${azurerm_resource_group.core_hub_rg.location}")
  resource_group_name          = azurerm_resource_group.core_hub_rg.name
  location                     = azurerm_resource_group.core_hub_rg.location
  platform_fault_domain_count  = var.core_hub_platform_fault_domain_count
  platform_update_domain_count = var.core_hub_platform_update_domain_count
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.core_hub_virtual_machine_name}-${azurerm_resource_group.core_hub_rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface - Commented since not needed in MCAPs subscription
#---------------------------------------------------------------
# resource "azurerm_network_security_group" "core_hub_nsg" {
#   name                = lower("nsg_${var.core_hub_virtual_machine_name}_${azurerm_resource_group.core_hub_rg.location}_in")
#   resource_group_name = azurerm_resource_group.core_hub_rg.name
#   location            = azurerm_resource_group.core_hub_rg.location
#   tags                = merge({ "ResourceName" = lower("nsg_${var.core_hub_virtual_machine_name}_${azurerm_resource_group.core_hub_rg.location}_in") }, var.tags, )
# }

# resource "azurerm_network_security_rule" "core_hub_nsg_rule" {
#   for_each                    = local.nsg_inbound_rules
#   name                        = each.key
#   priority                    = 100 * (each.value.idx + 1)
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = each.value.security_rule.destination_port_range
#   source_address_prefix       = each.value.security_rule.source_address_prefix
#   destination_address_prefix  = element(concat(azurerm_subnet.core_hub_snet.address_prefixes, [""]), 0)
#   description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
#   resource_group_name         = azurerm_resource_group.core_hub_rg.name
#   network_security_group_name = azurerm_network_security_group.core_hub_nsg.name
#   depends_on                  = [azurerm_network_security_group.core_hub_nsg]
# }

# resource "azurerm_network_interface_security_group_association" "core_hub_nsgassoc" {
#   count                     = var.core_hub_instances_count
#   network_interface_id      = element(concat(azurerm_network_interface.core_hub_nic.*.id, [""]), count.index)
#   network_security_group_id = azurerm_network_security_group.core_hub_nsg.id
# }

#---------------------------------------
# Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "core_hub_win_vm" {
  count                      = var.core_hub_os_flavor == "windows" ? var.core_hub_instances_count : 0
  name                       = var.core_hub_instances_count == 1 ? var.core_hub_virtual_machine_name : format("%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = var.core_hub_instances_count == 1 ? var.core_hub_virtual_machine_name : format("%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) # not more than 15 characters
  resource_group_name        = azurerm_resource_group.core_hub_rg.name
  location                   = azurerm_resource_group.core_hub_rg.location
  size                       = var.core_hub_virtual_machine_size
  admin_username             = var.core_hub_admin_username
  admin_password             = var.core_hub_admin_password == null ? element(concat(random_password.core_hub_passwd.*.result, [""]), 0) : var.core_hub_admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.core_hub_nic.*.id, [""]), count.index)]
  source_image_id            = var.core_hub_source_image_id != null ? var.core_hub_source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.core_hub_dedicated_host_id
  license_type               = var.core_hub_license_type
  availability_set_id        = var.core_hub_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.core_hub_aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = var.core_hub_instances_count == 1 ? var.core_hub_virtual_machine_name : format("%s%s", lower(replace(var.core_hub_virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  dynamic "source_image_reference" {
    for_each = var.core_hub_source_image_id != null ? [] : [1]
    content {
      publisher = var.core_hub_windows_distribution_list[lower(var.core_hub_windows_distribution_name)]["publisher"]
      offer     = var.core_hub_windows_distribution_list[lower(var.core_hub_windows_distribution_name)]["offer"]
      sku       = var.core_hub_windows_distribution_list[lower(var.core_hub_windows_distribution_name)]["sku"]
      version   = var.core_hub_windows_distribution_list[lower(var.core_hub_windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.core_hub_os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#---------------------------------------
# Promote Domain Controller
#---------------------------------------
resource "azurerm_virtual_machine_extension" "core_hub_adforest" {
  name                       = "ad-forest-creation"
  virtual_machine_id         = azurerm_windows_virtual_machine.core_hub_win_vm.0.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.core_hub_powershell_command}\""
    }
SETTINGS
}