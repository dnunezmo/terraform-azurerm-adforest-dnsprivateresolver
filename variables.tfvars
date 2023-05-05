
enable_public_ip_address = true

# Onpremises Resource Group, location, VNet and Subnet details
onprem_resource_group_name  = "onprem-rg-001"
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

azure_location                     = "westeurope"

# Core Hub Resource Group, location, VNet and Subnet details
core_hub_resource_group_name          = "core-hub-rg-001"
core_hub_virtual_network_name         = "core-hub-vnet"
core_hub_subnet_name                  = "core-hub-snet-management"
core_hub_inbound_subnet_name          = "core-hub-snet-inbound-endpoint"
core_hub_outbound_subnet_name         = "core-hub-snet-outbound-endpoint"
core_hub_private_endpoint_subnet_name = "core-hub-snet-private-endpoint"
core_hub_private_ip_address                 = ["10.0.0.4"]

# This module support multiple Pre-Defined Linux and Windows Distributions.
# Windows Images: windows2012r2dc, windows2016dc, windows2019dc
core_hub_virtual_machine_name               = "contoso-dc-01"
core_hub_windows_distribution_name          = "windows2019dc"
core_hub_virtual_machine_size               = "Standard_B2s"
core_hub_admin_username                     = "batman"
core_hub_admin_password                     = "P@$$w0rd1234!"
core_hub_private_ip_address_allocation_type = "Static"


# App Resource Group, location, VNet and Subnet details
app_resource_group_name              = "app-rg-001"
app_hub_virtual_network_name         = "app-hub-vnet"
app_hub_subnet_name                  = "app-hub-snet-vms"
app_hub_azure_firewall_subnet_name   = "AzureFirewallSubnet"

# App Resource Group, location, VNet and Subnet details
app_spoke_virtual_network_name         = "app-spoke-vnet"
app_spoke_subnet_name                  = "app-spoke-snet-vms"
app_spoke_private_endpoint_subnet_name = "app-spoke-snet-private-endpoint"

# This module support multiple Pre-Defined Linux and Windows Distributions.
# Windows Images: windows2012r2dc, windows2016dc, windows2019dc
app_spoke_virtual_machine_name               = "contoso-srv-01"
app_spoke_windows_distribution_name          = "windows2019dc"
app_spoke_virtual_machine_size               = "Standard_B2s"
app_spoke_admin_username                     = "batman"
app_spoke_admin_password                     = "P@$$w0rd1234!"
app_spoke_private_ip_address_allocation_type = "Dynamic"

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
    source_address_prefix  = "<<youriphere>>"
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
