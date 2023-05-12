
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
  depends_on = [ azurerm_subnet.onprem_snet ]

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
# Onpremises Network security group for Virtual Machine Network Interface - Commented since not needed in MCAPs subscription
#---------------------------------------------------------------
# resource "azurerm_network_security_group" "onprem_nsg" {
#   name                = lower("nsg_${var.onprem_virtual_machine_name}_${azurerm_resource_group.onprem_rg.location}_in")
#   resource_group_name = azurerm_resource_group.onprem_rg.name
#   location            = azurerm_resource_group.onprem_rg.location
#   tags                = merge({ "ResourceName" = lower("nsg_${var.onprem_virtual_machine_name}_${azurerm_resource_group.onprem_rg.location}_in") }, var.tags, )
# }

# resource "azurerm_network_security_rule" "onprem_nsg_rule" {
#   for_each                    = local.nsg_inbound_rules
#   name                        = each.key
#   priority                    = 100 * (each.value.idx + 1)
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = each.value.security_rule.destination_port_range
#   source_address_prefix       = each.value.security_rule.source_address_prefix
#   destination_address_prefix  = element(concat(azurerm_subnet.onprem_snet.address_prefixes, [""]), 0)
#   description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
#   resource_group_name         = azurerm_resource_group.onprem_rg.name
#   network_security_group_name = azurerm_network_security_group.onprem_nsg.name
#   depends_on                  = [azurerm_network_security_group.onprem_nsg]
# }

# resource "azurerm_network_interface_security_group_association" "onprem_nsgassoc" {
#   count                     = var.onprem_instances_count
#   network_interface_id      = element(concat(azurerm_network_interface.onprem_nic.*.id, [""]), count.index)
#   network_security_group_id = azurerm_network_security_group.onprem_nsg.id
# }

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