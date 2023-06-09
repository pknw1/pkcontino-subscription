variable "expiry" { default = 1 }


locals {
  current_time           = timestamp()
  today                  = formatdate("YYYY-MM-DD", local.current_time)
  hours                  = var.expiry * 24
  max_start_date         = formatdate("DD/MM/YYYY", timeadd(timestamp(), "${local.hours}h"))
}

resource "azurerm_resource_group" "rg" {
  name     = "ubuntu2204"
  location = "uksouth"
  tags     = { 
    expires =  local.max_start_date
    }    
}

# Create virtual network
resource "azurerm_virtual_network" "ubuntu2204_network" {
  name                = "ubuntu2204"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "ubuntu2204_subnet" {
  name                 = "ubuntu2204Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ubuntu2204_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "ubuntu2204_public_ip" {
  name                = "ubuntu2204PublicIP"
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
resource "azurerm_network_security_group" "ubuntu2204_nsg" {
  # checkov:skip=BC_AZR_NETWORKING_3: ADD REASON
  name                = "ubuntu2204NetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "ubuntu2204_nic" {
  # checkov:skip=BC_AZR_NETWORKING_36: ADD REASON
  name                = "ubuntu2204NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ubuntu2204_nic_configuration"
    subnet_id                     = azurerm_subnet.ubuntu2204_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu2204_public_ip.id
  }

    timeouts {
      delete = "2h"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.ubuntu2204_nic.id
  network_security_group_id = azurerm_network_security_group.ubuntu2204_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_ssh_public_key" "pknw1" {
  name                = "pknw1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("id_rsa.pub")
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "ubuntu2204_vm" {
  # checkov:skip=BC_AZR_GENERAL_14: ADD REASON
  name                  = "ubuntu2204VM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.ubuntu2204_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "ubuntu2204OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "ubuntu2204vm"
  admin_username                  = "pknw1"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "pknw1"
    public_key = azurerm_ssh_public_key.pknw1.public_key
  }

  #boot_diagnostics {
  #  storage_account_uri = azurerm_storage_account.ubuntu2204_storage_account.primary_blob_endpoint
  #}

  depends_on = [ azurerm_network_interface_security_group_association.example ]
}


resource "azurerm_virtual_machine_extension" "configureLinuxRunner" {
  name                 = "scripts"
  virtual_machine_id   = azurerm_linux_virtual_machine.ubuntu2204_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  depends_on = [ azurerm_linux_virtual_machine.ubuntu2204_vm ]

  settings = <<SETTINGS
 {
  "commandToExecute": "apt update && apt upgrade -yq"
 }
SETTINGS

    lifecycle {
        #ignore_changes = all
        ignore_changes = [ tags, ]
    }
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ubuntu2204_vm.public_ip_address
}