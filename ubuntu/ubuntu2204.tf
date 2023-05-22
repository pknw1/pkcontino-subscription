resource "azurerm_resource_group" "rg" {
  name     = "ubuntu"
  location = "uksouth"
}

# Create virtual network
resource "azurerm_virtual_network" "ubuntu_network" {
  name                = "ubuntu"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "ubuntu_subnet" {
  name                 = "ubuntuSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ubuntu_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "ubuntu_public_ip" {
  name                = "ubuntuPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ubuntu_nsg" {
  name                = "ubuntuNetworkSecurityGroup"
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
resource "azurerm_network_interface" "ubuntu_nic" {
  name                = "ubuntuNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ubuntu_nic_configuration"
    subnet_id                     = azurerm_subnet.ubuntu_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.ubuntu_nic.id
  network_security_group_id = azurerm_network_security_group.ubuntu_nsg.id
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
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                  = "ubuntuVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.ubuntu_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "ubuntuOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }


  computer_name                   = "ubuntuvm"
  admin_username                  = "pknw1"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "pknw1"
    public_key = azurerm_ssh_public_key.pknw1.public_key
  }

  #boot_diagnostics {
  #  storage_account_uri = azurerm_storage_account.ubuntu_storage_account.primary_blob_endpoint
  #}
}


resource "azurerm_virtual_machine_extension" "configureLinuxRunner" {
  name                 = "configureLinuxRunner"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux_runner.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  depends_on = [ azurerm_storage_blob.configureLinuxRunner, azurerm_role_assignment.linux_runner_storage,azurerm_storage_account.storage, azurerm_storage_account.support ]
  
  settings = <<SETTINGS
 {
  "commandToExecute": "hostname && uptime && touch /pknw1"
 }
SETTINGS

    lifecycle {
        #ignore_changes = all
        ignore_changes = [ tags, ]
    }
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ubuntu_vm.public_ip_address
}