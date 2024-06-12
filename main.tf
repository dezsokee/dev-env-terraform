# Specify the Azure provider and version
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
  name     = "libman-rg"
  location = "East US"
  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}

resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-vn"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}

resource "azurerm_subnet" "mtc-sn" {
  name                 = "mtc-sn"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "mtc-nsg" {
  name                = "mtc-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}

resource "azurerm_network_security_rule" "mtc-nsr" {
  name                        = "mtc-nsr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destinatio_address_prefix   = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.mtc-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "mtc-sn-nsg" {
  subnet_id                 = azurerm_subnet.mtc-sn.id
  network_security_group_id = azurerm_network_security_group.mtc-nsg.id
}

resource "azurerm_public_ip" "mtc-pip" {
  name                = "mtc-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}

resource "azurerm_network_interface" "mtc-nic" {
  name                = "mtc-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "mtc-nic-ip"
    subnet_id                     = azurerm_subnet.mtc-sn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-pip.id
  }

  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}

resource "azurerm_virtual_machine" "mtc-vm" {
  name                  = "mtc-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.mtc-nic.id]
  vm_size               = "Standard_DS1_v2"

  custom_data = filebase64("customdata.tpl")

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "mtc-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "mtc-vm"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  tags = {
    environment = "dev",
    project     = "libman",
    author      = "dezsokee"
  }
}