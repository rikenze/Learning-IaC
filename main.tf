# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "HenteqTFResourceGroup"
  location = "westus2"
}

# Network (VNet e Subnet)
resource "azurerm_virtual_network" "vnet" {
  name                = "HenteqTFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "henteqTFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "henteqTFPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "henteqTFNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 🔹 Linux Virtual Machine (equivalente ao aws_instance)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "henteqTFVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  size = "Standard_B1s"  # similar ao t2.micro

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "myvm"
  admin_username = "azureuser"

  # user_data = base64encode(
  #   <<-EOF
  #       #! bin/bash
  #       echo '<h1>Feito com o Terraform</h1>' > /home/azureuser/index.html
  #       nohup busybox httpd -f -p 8080 &
  #      EOF
  # )

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa_azure.pub") 
  }

  tags = {
    Name = "henteq-terraform"
  }
}