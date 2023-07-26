provider "azurerm" {  
  features {}
}
resource "azurerm_security_center_subscription_pricing" "AzureSC_Malware_Test" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

variable "admin_password" {
  description = "Password for the virtual machine admin"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "example-resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "West US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vM-vNet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "example" {
  name                = "vM-publicip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = "vM-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "vM1"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_id  = azurerm_network_interface.example.id
  vm_size               = "Standard_B2s"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                 = "vM-MalwareService"
  virtual_machine_id   = azurerm_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Security"
  type                 = "IaaSAntimalware"
  type_handler_version = "1.5"

  settings = <<SETTINGS
    {
        "AntimalwareEnabled": true,
        "RealtimeProtectionEnabled": "true"
    }
SETTINGS
}
