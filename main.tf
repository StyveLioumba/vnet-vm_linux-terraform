# 1 - Créer un  groupe de ressource
# description :
# Un groupe de ressources est un conteneur logique dans lequel les ressources Azure sont déployées et gérées.
resource "azurerm_resource_group" "rg_main" {
  location = "westeurope"
  name     = "rg-main"
}

# 2 - Créer un réseau virtuel
# description :
# Un réseau virtuel est un réseau isolé logiquement dans le cloud Azure. Vous pouvez l'utiliser pour contrôler la connectivité réseau à partir de vos ressources et vers Internet.
resource "azurerm_virtual_network" "vnet_main" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  name                = "vnet-main"
}

# 3 - Créer un sous-réseau
# description :
# Un sous-réseau est un sous-ensemble d'adresses IP dans un réseau virtuel Azure.
resource "azurerm_subnet" "subnet_main" {
  address_prefixes            = ["10.0.1.0/24"]
  name                        = "subnet-main"
  resource_group_name         = azurerm_resource_group.rg_main.name
  virtual_network_name        = azurerm_virtual_network.vnet_main.name
}

# 4 - Créer un groupe de sécurité réseau et une règle de sécurité
# description :
# Un groupe de sécurité réseau est un ensemble de règles de sécurité qui contrôlent le trafic réseau entrant et sortant de votre VM.
resource "azurerm_network_security_group" "nsg_main" {
  location            = azurerm_resource_group.rg_main.location
  name                = "nsg-main"
  resource_group_name = azurerm_resource_group.rg_main.name

  security_rule {
    name                       = "allow-ssh-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "Allow-web"
    description                = "Allow web"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "10.0.1.0/24"
  }

  }

# 5 - Créer une association entre le groupe de sécurité réseau et le sous-réseau
# description :
# L'association entre le groupe de sécurité réseau et le sous-réseau permet de contrôler le flux du trafic réseau entrant et sortant de votre VM.
resource "azurerm_subnet_network_security_group_association" "snsga_main" {
  network_security_group_id = azurerm_network_security_group.nsg_main.id
  subnet_id                 = azurerm_subnet.subnet_main.id
}

# 6 - Créer une adresse IP publique
# description :
# Une adresse IP publique est une adresse IP qui peut être utilisée pour accéder à votre machine virtuelle à partir d'Internet.
resource "azurerm_public_ip" "public_ip_main" {
  allocation_method   = "Dynamic"
  location            = azurerm_resource_group.rg_main.location
  name                = "public-ip-main"
  resource_group_name = azurerm_resource_group.rg_main.name
}

# 7 - Créer une interface réseau
# description :
# Une interface réseau est un point de connexion entre une machine virtuelle et un réseau virtuel.
resource "azurerm_network_interface" "nw_interface_main" {
  location            = azurerm_resource_group.rg_main.location
  name                = "nw-interface-main"
  resource_group_name = azurerm_resource_group.rg_main.name

  ip_configuration {
    name                          = "nw-interface-main-ip-config"
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.subnet_main.id
    public_ip_address_id = azurerm_public_ip.public_ip_main.id
  }
}

# 8 - Créer une machine virtuelle
# description :
# Une machine virtuelle est un ordinateur virtuel qui fonctionne comme un ordinateur physique avec un système d'exploitation.
resource "azurerm_linux_virtual_machine" "vm_linux_main" {
  location              = azurerm_resource_group.rg_main.location
  name                  = "vm-linux-main"
  network_interface_ids = [azurerm_network_interface.nw_interface_main.id]
  resource_group_name   = azurerm_resource_group.rg_main.name
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!"
  size                  = "Standard_F2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  disable_password_authentication = false

}
