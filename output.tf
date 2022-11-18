output "onprem_windows_vm_password" {
  description = "Password for the windows VM"
  sensitive   = true
  value       = var.onprem_os_flavor == "windows" && var.onprem_admin_password == null ? element(concat(random_password.onprem_passwd.*.result, [""]), 0) : null
}

output "onprem_windows_vm_domain_name_label" {
  description = "FQDN for the all windows Virtual Machines"
  value       = var.enable_public_ip_address == true && var.onprem_os_flavor == "windows" ? zipmap(azurerm_public_ip.onprem_pip.*.domain_name_label, azurerm_public_ip.onprem_pip.*.ip_address) : null
}

output "onprem_windows_vm_public_ips" {
  description = "Public IP's map for the all windows Virtual Machines"
  value       = var.enable_public_ip_address == true && var.onprem_os_flavor == "windows" ? zipmap(azurerm_windows_virtual_machine.onprem_win_vm.*.name, azurerm_windows_virtual_machine.onprem_win_vm.*.public_ip_address) : null
}

output "onprem_windows_vm_private_ips" {
  description = "Public IP's map for the all windows Virtual Machines"
  value       = var.onprem_os_flavor == "windows" ? zipmap(azurerm_windows_virtual_machine.onprem_win_vm.*.name, azurerm_windows_virtual_machine.onprem_win_vm.*.private_ip_address) : null
}

output "onprem_windows_virtual_machine_ids" {
  description = "The resource id's of all Windows Virtual Machine."
  value       = var.onprem_os_flavor == "windows" ? element(concat(azurerm_windows_virtual_machine.onprem_win_vm.*.id, [""]), 0) : null
}

output "onprem_network_security_group_ids" {
  description = "List of Network security groups and ids"
  value       = azurerm_network_security_group.onprem_nsg.id
}

output "onprem_vm_availability_set_id" {
  description = "The resource ID of Virtual Machine availability set"
  value       = var.onprem_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.onprem_aset.*.id, [""]), 0) : null
}

output "onprem_active_directory_domain" {
  description = "The name of the active directory domain"
  value       = var.onprem_active_directory_domain
}

output "onprem_active_directory_netbios_name" {
  description = "The name of the active directory netbios name"
  value       = var.onprem_active_directory_netbios_name
}

# ==============================================================

output "azure_windows_vm_password" {
  description = "Password for the windows VM"
  sensitive   = true
  value       = var.azure_os_flavor == "windows" && var.azure_admin_password == null ? element(concat(random_password.azure_passwd.*.result, [""]), 0) : null
}

output "azure_windows_vm_domain_name_label" {
  description = "Public IP's map for the all windows Virtual Machines"
  value       = var.enable_public_ip_address == true && var.azure_os_flavor == "windows" ? zipmap(azurerm_public_ip.azure_pip.*.domain_name_label, azurerm_public_ip.azure_pip.*.ip_address) : null
}

output "azure_windows_vm_public_ips" {
  description = "Public IP's map for the all windows Virtual Machines"
  value       = var.enable_public_ip_address == true && var.azure_os_flavor == "windows" ? zipmap(azurerm_windows_virtual_machine.azure_win_vm.*.name, azurerm_windows_virtual_machine.azure_win_vm.*.public_ip_address) : null
}

output "azure_windows_vm_private_ips" {
  description = "Public IP's map for the all windows Virtual Machines"
  value       = var.azure_os_flavor == "windows" ? zipmap(azurerm_windows_virtual_machine.azure_win_vm.*.name, azurerm_windows_virtual_machine.azure_win_vm.*.private_ip_address) : null
}

output "azure_windows_virtual_machine_ids" {
  description = "The resource id's of all Windows Virtual Machine."
  value       = var.azure_os_flavor == "windows" ? element(concat(azurerm_windows_virtual_machine.azure_win_vm.*.id, [""]), 0) : null
}

output "azure_network_security_group_ids" {
  description = "List of Network security groups and ids"
  value       = azurerm_network_security_group.azure_nsg.id
}

output "azure_vm_availability_set_id" {
  description = "The resource ID of Virtual Machine availability set"
  value       = var.azure_enable_vm_availability_set == true ? element(concat(azurerm_availability_set.azure_aset.*.id, [""]), 0) : null
}

output "azure_active_directory_domain" {
  description = "The name of the active directory domain"
  value       = var.azure_active_directory_domain
}

output "azure_active_directory_netbios_name" {
  description = "The name of the active directory netbios name"
  value       = var.azure_active_directory_netbios_name
}
