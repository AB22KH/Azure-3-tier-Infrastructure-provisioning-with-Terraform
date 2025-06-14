variable "Vnet_tags" {
  type = map(string)
  default = {
    environment = "Production"
    team        = "development"
    AD_number   = "1"
  }
}
variable "VM_tags" {
  type = map(string)
  default = {
    environment = "Production"
    team        = "development"
    AD_number   = "1"
    new_vm_tag  = "recently_added_tag"
  }
}
variable "DB_tags" {
  type = map(string)
  default = {
    environment = "Production"
    team        = "development"
    AD_number   = "1"
  }
}

variable "RG_location" {
  default = "West Europe"
}

variable "vnet_address_space" {
  default = ["10.0.0.0/16"]
}

variable "vnet_dns" {
  default = ["10.0.0.4", "10.0.0.5"]
}

variable "LB_Subnet_address_prefix" {
  default = ["10.0.1.0/24"]
}
variable "VM_Subnet_address_prefix" {
  default = ["10.0.2.0/24"]
}
variable "DB_Subnet_address_prefix" {
  default = ["10.0.3.0/24"]
}

variable "VM_OS_profile" {
  type = map(string)
  default = {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
}


variable "DB_max_size" {
  default = 2
}




variable "LM_NSG_Rules" {
  type = map(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {
    "rule1" = {
      name                       = "rule1"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "22"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "rule2" = {
      name                       = "rule2"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "3000"
      destination_port_range     = "3000"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
