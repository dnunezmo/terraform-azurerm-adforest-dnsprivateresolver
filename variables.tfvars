
enable_public_ip_address = true

# Onpremises Resource Group, location, VNet and Subnet details
onprem_resource_group_name  = "onprem-net-001"
onprem_location             = "westeurope"
onprem_virtual_network_name = "onprem-vnet"
onprem_subnet_name          = "onprem-snet-management"

# This module support multiple Pre-Defined Linux and Windows Distributions.
# Windows Images: windows2012r2dc, windows2016dc, windows2019dc
onprem_virtual_machine_name               = "onprem-dc-01"
onprem_windows_distribution_name          = "windows2019dc"
onprem_virtual_machine_size               = "Standard_B2s"
onprem_admin_username                     = "batman"
onprem_admin_password                     = "P@$$w0rd1234!"
onprem_private_ip_address_allocation_type = "Static"
onprem_private_ip_address                 = ["10.8.0.4"]

# Active Directory domain and netbios details
# Intended for test/demo purposes
# For production use of this module, fortify the security by adding correct nsg rules
onprem_active_directory_domain       = "onprem.com"
onprem_active_directory_netbios_name = "ONPREM"

# Azure Resource Group, location, VNet and Subnet details
azure_resource_group_name          = "contoso-hub-001"
azure_location                     = "westeurope"
azure_virtual_network_name         = "contoso-vnet"
azure_subnet_name                  = "contoso-snet-management"
azure_inbound_subnet_name          = "contoso-snet-inbound-endpoint"
azure_outbound_subnet_name         = "contoso-snet-outbound-endpoint"
azure_private_endpoint_subnet_name = "contoso-snet-private-endpoint"

# This module support multiple Pre-Defined Linux and Windows Distributions.
# Windows Images: windows2012r2dc, windows2016dc, windows2019dc
azure_virtual_machine_name               = "contoso-dc-01"
azure_windows_distribution_name          = "windows2019dc"
azure_virtual_machine_size               = "Standard_B2s"
azure_admin_username                     = "batman"
azure_admin_password                     = "P@$$w0rd1234!"
azure_private_ip_address_allocation_type = "Static"
azure_private_ip_address                 = ["10.0.0.4"]

# Active Directory domain and netbios details
# Intended for test/demo purposes
# For production use of this module, fortify the security by adding correct nsg rules
azure_active_directory_domain       = "contoso.com"
azure_active_directory_netbios_name = "CONTOSO"

# Network Seurity group port allow definitions for each Virtual Machine
# NSG association to be added automatically for all network interfaces.
# SSH port 22 and 3389 is exposed to the Internet recommended for only testing.
# For production environments, we recommend using a VPN or private connection
nsg_inbound_rules = [
  {
    name                   = "rdp"
    destination_port_range = "3389"
    source_address_prefix  = "<your-public-IP-address>"
  },
]

# Adding TAG's to your Azure resources (Required)
# ProjectName and Env are already declared above, to use them here, create a varible.
tags = {
  ProjectName  = "Private-Resolver-demo"
  Env          = "test"
  Owner        = "user@example.com"
  BusinessUnit = "consulting"
}
