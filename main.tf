resource "azurerm_resource_group" "my_RG" {
  name     = "my_RG"
  location = var.RG_location
}

resource "azurerm_network_security_group" "my_SG" {
  name                = "my_SG"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name
}

resource "azurerm_virtual_network" "my_Vnet" {
  name                = "my_Vnet"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name
  address_space       = var.vnet_address_space
  dns_servers         = var.vnet_dns

  tags = var.Vnet_tags
}


resource "azurerm_subnet" "LB_Subnet" {
  name                 = "LB_Subnet-subnet"
  resource_group_name  = azurerm_resource_group.my_RG.name
  virtual_network_name = azurerm_virtual_network.my_Vnet.name
  address_prefixes     = var.LB_Subnet_address_prefix
}
resource "azurerm_subnet" "VM_Subnet" {
  name                 = "VM_Subnet-subnet"
  resource_group_name  = azurerm_resource_group.my_RG.name
  virtual_network_name = azurerm_virtual_network.my_Vnet.name
  address_prefixes     = var.VM_Subnet_address_prefix
}
resource "azurerm_subnet" "DB_Subnet" {
  name                 = "DB_Subnet-subnet"
  resource_group_name  = azurerm_resource_group.my_RG.name
  virtual_network_name = azurerm_virtual_network.my_Vnet.name
  address_prefixes     = var.DB_Subnet_address_prefix
}

resource "azurerm_public_ip" "PublicIPForLB" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "LB_NSG" {
  name                = "LB_NSG"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name

 dynamic "security_rule" {
  for_each = var.LM_NSG_Rules
  content {
    name                       = security_rule.value.name
    priority                   = security_rule.value.priority
    direction                  = security_rule.value.direction
    access                     = security_rule.value.access
    protocol                   = security_rule.value.protocol
    source_port_range          = security_rule.value.source_port_range
    destination_port_range     = security_rule.value.destination_port_range
    source_address_prefix      = security_rule.value.source_address_prefix
    destination_address_prefix = security_rule.value.destination_address_prefix
  }
 } 
}
resource "azurerm_network_security_group" "VM_NSG" {
  name                = "VM_NSG"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name

  security_rule {
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
}


resource "azurerm_lb" "my_LoadBalancer" {
  name                = "my_LoadBalancer"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.PublicIPForLB.id
    subnet_id            = azurerm_subnet.LB_Subnet.id
  }
}
resource "azurerm_subnet_network_security_group_association" "LB_NSG_Association" {
  subnet_id                 = azurerm_subnet.LB_Subnet.id
  network_security_group_id = azurerm_network_security_group.LB_NSG.id
}

resource "azurerm_network_interface" "my-nic" {
  name                = "my-nic"
  location            = azurerm_resource_group.my_RG.location
  resource_group_name = azurerm_resource_group.my_RG.name

  ip_configuration {
    name                          = "VM_NIC_Attachment"
    subnet_id                     = azurerm_subnet.VM_Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "my_vm" {
  name                  = "my_vm"
  location              = azurerm_resource_group.my_RG.location
  resource_group_name   = azurerm_resource_group.my_RG.name
  network_interface_ids = [azurerm_network_interface.my-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.VM_OS_profile.computer_name
    admin_username = var.VM_OS_profile.admin_username
    admin_password = var.VM_OS_profile.admin_username
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }


  tags = var.VM_tags
}

resource "azurerm_network_interface_security_group_association" "VM_NSG_Association" {
  network_interface_id      = azurerm_network_interface.my-nic.id
  network_security_group_id = azurerm_network_security_group.VM_NSG.id
}

resource "azurerm_mssql_server" "my_DB_server" {
  name                         = "my_DB_server"
  resource_group_name          = azurerm_resource_group.my_RG.name
  location                     = azurerm_resource_group.my_RG.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_database" "my_DB" {
  name         = "my_DB"
  server_id    = azurerm_mssql_server.my_DB_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = var.DB_max_size
  sku_name     = "S0"
  enclave_type = "VBS"

  tags = var.DB_tags
  lifecycle {
    prevent_destroy = true
  }
}
