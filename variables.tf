variable "onprem_resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "onprem_location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "onprem_virtual_network_name" {
  description = "The name of the virtual network"
  default     = ""
}

variable "onprem_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "onprem_virtual_machine_name" {
  description = "The name of the virtual machine."
  default     = ""
}

variable "onprem_os_flavor" {
  description = "Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux`"
  default     = "windows"
}

variable "onprem_virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
  default     = "Standard_A2_v2"
}

variable "onprem_instances_count" {
  description = "The number of Virtual Machines required."
  default     = 1
}

variable "onprem_enable_ip_forwarding" {
  description = "Should IP Forwarding be enabled? Defaults to false"
  default     = false
}

variable "onprem_enable_accelerated_networking" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = false
}

variable "onprem_private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  default     = "Dynamic"
}

variable "onprem_private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  default     = null
}

variable "onprem_dns_servers" {
  description = "List of dns servers to use for network interface"
  default     = []
}

variable "onprem_enable_vm_availability_set" {
  description = "Manages an Availability Set for Virtual Machines."
  default     = false
}

variable "onprem_platform_update_domain_count" {
  description = "Specifies the number of update domains that are used"
  default     = 5
}

variable "onprem_platform_fault_domain_count" {
  description = "Specifies the number of fault domains that are used"
  default     = 3
}

variable "enable_public_ip_address" {
  description = "Reference to a Public IP Address to associate with the NIC"
  default     = null
}

variable "onprem_source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  default     = null
}

variable "onprem_windows_distribution_list" {
  description = "Pre-defined Azure Windows VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    windows2012r2dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
      version   = "latest"
    },

    windows2016dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter"
      version   = "latest"
    },

    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },
  }
}

variable "onprem_windows_distribution_name" {
  default     = "windows2019dc"
  description = "Variable to pick an OS flavour for Windows based VM. Possible values include: winserver, wincore, winsql"
}

variable "onprem_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "Standard_LRS"
}

variable "onprem_admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  default     = "azureadmin"
}

variable "onprem_admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  default     = null
}

variable "nsg_inbound_rules" {
  description = "List of network rules to apply to network interface."
  default     = []
}

variable "onprem_dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine should be run on."
  default     = null
}

variable "onprem_license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "None"
}

variable "onprem_active_directory_domain" {
  description = "The name of the Active Directory domain, for example `consoto.com`"
  default     = ""
}

variable "onprem_active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "core_hub_resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "core_hub_virtual_network_name" {
  description = "The name for the virtual network hub"
  default     = ""
}

variable "azure_location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "core_hub_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "core_hub_private_endpoint_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "core_hub_inbound_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "core_hub_outbound_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}
variable "core_hub_virtual_machine_name" {
  description = "The name of the virtual machine."
  default     = ""
}

variable "core_hub_os_flavor" {
  description = "Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux`"
  default     = "windows"
}

variable "core_hub_virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
  default     = "Standard_A2_v2"
}

variable "core_hub_instances_count" {
  description = "The number of Virtual Machines required."
  default     = 1
}

variable "core_hub_enable_ip_forwarding" {
  description = "Should IP Forwarding be enabled? Defaults to false"
  default     = false
}

variable "core_hub_enable_accelerated_networking" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = false
}

variable "core_hub_private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  default     = "Dynamic"
}

variable "core_hub_private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  default     = null
}

variable "core_hub_dns_servers" {
  description = "List of dns servers to use for network interface"
  default     = []
}

variable "core_hub_enable_vm_availability_set" {
  description = "Manages an Availability Set for Virtual Machines."
  default     = false
}

variable "core_hub_platform_update_domain_count" {
  description = "Specifies the number of update domains that are used"
  default     = 5
}

variable "core_hub_platform_fault_domain_count" {
  description = "Specifies the number of fault domains that are used"
  default     = 3
}

variable "core_hub_source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  default     = null
}

variable "core_hub_windows_distribution_list" {
  description = "Pre-defined Azure Windows VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    windows2012r2dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
      version   = "latest"
    },

    windows2016dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter"
      version   = "latest"
    },

    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },
  }
}

variable "core_hub_windows_distribution_name" {
  default     = "windows2019dc"
  description = "Variable to pick an OS flavour for Windows based VM. Possible values include: winserver, wincore, winsql"
}

variable "core_hub_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "Standard_LRS"
}

variable "core_hub_admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  default     = "azureadmin"
}

variable "core_hub_admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  default     = null
}

variable "core_hub_dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine should be run on."
  default     = null
}

variable "core_hub_license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "None"
}

variable "core_hub_active_directory_domain" {
  description = "The name of the Active Directory domain, for example `consoto.com`"
  default     = ""
}

variable "core_hub_active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  default     = ""
}

variable "app_resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "app_hub_virtual_network_name" {
  description = "The name for the virtual network hub"
  default     = ""
}

variable "app_hub_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "app_hub_azure_firewall_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = "AzureFirewallSubnet"
}

variable "app_spoke_virtual_machine_name" {
  description = "The name of the virtual machine."
  default     = ""
}

variable "app_spoke_os_flavor" {
  description = "Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux`"
  default     = "windows"
}

variable "app_spoke_virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
  default     = "Standard_A2_v2"
}

variable "app_spoke_instances_count" {
  description = "The number of Virtual Machines required."
  default     = 1
}

variable "app_spoke_enable_ip_forwarding" {
  description = "Should IP Forwarding be enabled? Defaults to false"
  default     = false
}

variable "app_spoke_enable_accelerated_networking" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = false
}

variable "app_spoke_private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  default     = "Dynamic"
}

variable "app_spoke_private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  default     = null
}

variable "app_spoke_dns_servers" {
  description = "List of dns servers to use for network interface"
  default     = []
}

variable "app_spoke_enable_vm_availability_set" {
  description = "Manages an Availability Set for Virtual Machines."
  default     = false
}

variable "app_spoke_platform_update_domain_count" {
  description = "Specifies the number of update domains that are used"
  default     = 5
}

variable "app_spoke_platform_fault_domain_count" {
  description = "Specifies the number of fault domains that are used"
  default     = 3
}

variable "app_spoke_source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  default     = null
}

variable "app_spoke_windows_distribution_list" {
  description = "Pre-defined Azure Windows VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    windows2012r2dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
      version   = "latest"
    },

    windows2016dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter"
      version   = "latest"
    },

    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },
  }
}

variable "app_spoke_windows_distribution_name" {
  default     = "windows2019dc"
  description = "Variable to pick an OS flavour for Windows based VM. Possible values include: winserver, wincore, winsql"
}

variable "app_spoke_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "Standard_LRS"
}

variable "app_spoke_admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  default     = "azureadmin"
}

variable "app_spoke_admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  default     = null
}

variable "app_spoke_dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine should be run on."
  default     = null
}

variable "app_spoke_license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "None"
}





variable "app_spoke_virtual_network_name" {
  description = "The name for the virtual network hub"
  default     = ""
}

variable "app_spoke_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "app_spoke_private_endpoint_subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}
