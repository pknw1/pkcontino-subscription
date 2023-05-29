variable "expiry" { default = 1 }


locals {
  current_time           = timestamp()
  today                  = formatdate("YYYY-MM-DD", local.current_time)
  hours                  = var.expiry * 24
  max_start_date         = formatdate("DD/MM/YYYY", timeadd(timestamp(), "${local.hours}h"))
}

resource "azurerm_resource_group" "rg" {
  name     = "win11"
  location = "uksouth"
  tags     = { 
    expires =  local.max_start_date
    }    
}

# Create virtual network
resource "azurerm_virtual_network" "win11_network" {
  name                = "win11"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "win11_subnet" {
  name                 = "win11Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.win11_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "win11_public_ip" {
  name                = "win11PublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

    timeouts {
      delete = "2h"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "win11_nsg" {
  # checkov:skip=BC_AZR_NETWORKING_57: ADD REASON
  # checkov:skip=BC_AZR_NETWORKING_2: ADD REASON
  name                = "win11NetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  
  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "win11_nic" {
  # checkov:skip=BC_AZR_NETWORKING_36: ADD REASON
  name                = "win11NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "win11_nic_configuration"
    subnet_id                     = azurerm_subnet.win11_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.win11_public_ip.id
  }

    timeouts {
      delete = "2h"
  }
  depends_on = [azurerm_public_ip.win11_public_ip]
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.win11_nic.id
  network_security_group_id = azurerm_network_security_group.win11_nsg.id

  depends_on = [ azurerm_network_interface.win11_nic,
  azurerm_network_security_group.win11_nsg 
  ]
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}


resource "azurerm_windows_virtual_machine" "main" {
  # checkov:skip=BC_AZR_GENERAL_14: ADD REASON
  # checkov:skip=BC_AZR_GENERAL_89: ADD REASON
  name                  = "win11"
  admin_username        = "pknw1"
  admin_password        = random_password.password.result
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.win11_nic.id]
  size                  = "Standard_B2ms"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-pron"
    version   = "latest"
  }
  encryption_at_host_enabled = false
  allow_extension_operations = true

    depends_on = [ azurerm_network_interface_security_group_association.example ]

}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}


#resource "azurerm_virtual_machine_extension" "web_server_install" {
#  name                       = "${random_id.random_id.id}-wsi"
#  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
#  publisher                  = "Microsoft.Compute"
#  type                       = "CustomScriptExtension"
#  type_handler_version       = "1.8"
#  auto_upgrade_minor_version = true#

#  settings = <<SETTINGS
#    {
#      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
#    }
#  SETTINGS
#}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.main.public_ip_address
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.main.admin_password
}
