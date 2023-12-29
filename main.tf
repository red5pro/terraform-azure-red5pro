locals {
  single                           = var.type == "single" ? true : false
  cluster                          = var.type == "cluster" ? true : false
  autoscaling                      = var.type == "autoscaling" ? true : false
  image_offer                      = var.ubuntu_version == "22.04" ? "0001-com-ubuntu-server-jammy" : "0001-com-ubuntu-server-focal"
  image_sku                        = var.ubuntu_version == "22.04" ? "22_04-lts" : "20_04-lts"
  ssh_private_key_path             = var.create_new_ssh_keys ? local_file.red5pro_ssh_key_pem[0].filename : var.existing_private_ssh_key_path
  az_resource_group                = var.create_azure_resource_group ? azurerm_resource_group.az_resource_group[0].name : var.existing_azure_resource_group_name
  public_ssh_key                   = var.create_new_ssh_keys ? tls_private_key.red5pro_ssh_key[0].public_key_openssh : file(var.existing_public_ssh_key_path)
  private_ssh_key                  = var.create_new_ssh_keys ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.existing_private_ssh_key_path)
  stream_manager_ip                = local.cluster || local.autoscaling ? azurerm_linux_virtual_machine.red5_stream_manager[0].public_ip_address : null
  mysql_local_enable               = local.autoscaling ? false : local.cluster && var.mysql_database_create ? false : true
  mysql_host                       = local.autoscaling ? azurerm_mysql_server.red5_database[0].fqdn : local.cluster && var.mysql_database_create ? azurerm_mysql_server.red5_database[0].fqdn : "localhost"
  mysql_db_system_create           = local.autoscaling ? true : local.cluster && var.mysql_database_create ? true : false
  single_server_ip                 = local.single ? azurerm_linux_virtual_machine.red5_single[0].public_ip_address : null
}

################################################################################
# SSH_KEY
################################################################################
# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count               = var.create_new_ssh_keys ? 1 : 0
  algorithm           = "RSA"
  rsa_bits            = 4096
}
# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count               = var.create_new_ssh_keys ? 1 : 0
  filename            = "./${var.ssh_key_name}.pem"
  content             = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission     = "0400"
}

resource "local_file" "red5pro_ssh_key_pub" {
  count               = var.create_new_ssh_keys ? 1 : 0
  filename            = "./${var.ssh_key_name}.pub"
  content             = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

resource "azurerm_ssh_public_key" "red5pro_ssh" {
  count               = var.create_new_ssh_keys ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-${var.ssh_key_name}"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  public_key          = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Use already created ssh keys of azure account
data "azurerm_ssh_public_key" "existing_red5pro_ssh" {
  count               = var.create_new_ssh_keys ? 0 : 1
  name                = var.existing_ssh_key_name
  resource_group_name = local.az_resource_group
}

################################################################################
# Azure Resource Group 
################################################################################
# Create a new resource group in azure account
resource "azurerm_resource_group" "az_resource_group" {
  count               = var.create_azure_resource_group ? 1 : 0
  name                = var.new_azure_resource_group_name
  location            = var.azure_region
}

data "azurerm_resources" "existing_az_resource" {
  count               = var.create_azure_resource_group ? 0 : 1
  resource_group_name = var.existing_azure_resource_group_name
}

################################################################################
# VPC - Create new/existing (VPC)
################################################################################
resource "azurerm_virtual_network" "red5_vpc" {
  count               = var.vpc_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-vnet"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  address_space       = [var.vpc_cidr_block]
}

resource "azurerm_subnet" "vpc_subnet" {
  count                = var.vpc_create ? 1 : 0
  name                 = "${var.name}-${var.azure_region}-red5-subnet"
  resource_group_name  = local.az_resource_group
  virtual_network_name = azurerm_virtual_network.red5_vpc[0].name
  address_prefixes     = cidrsubnets(var.vpc_cidr_block, 4)
}

################################################################################
# Red5 Pro Single Server Network Configuration
################################################################################
resource "azurerm_public_ip" "single_public-ip" {
  count               = local.single ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-single-public-ip"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "red5_single_network_interface" {
  count               = local.single ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-single-nic"
  location            = var.azure_region
  resource_group_name = local.az_resource_group

  ip_configuration {
    name                          = "${var.name}-${var.azure_region}-red5-single-ip-configuration"
    subnet_id                     = azurerm_subnet.vpc_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.single_public-ip[0].id
  }
}

resource "azurerm_network_security_group" "single_red5_network_security_group" {
  count               = local.single ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-single-nsg"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-single-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.single_red5_nsg_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "network-interface-security-association" {
  count                     = local.single ? 1 : 0
  network_interface_id      = azurerm_network_interface.red5_single_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.single_red5_network_security_group[0].id
}
################################################################################
# Red5 Pro Node Network Configuration
################################################################################
resource "azurerm_public_ip" "node_public_ip" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-node-public-ip"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "node_network_interface" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-node-network-interface"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  ip_configuration {
    name                          = "${var.name}-${var.azure_region}-node-ip-configuration"
    subnet_id                     = azurerm_subnet.vpc_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node_public_ip[0].id
  }
}

resource "azurerm_network_security_group" "red5_node_network_security_group" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-node-nsg"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-node-tcp-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.origin_red5_tcp_nsg_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-node-udp-nsg-rule"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = [var.origin_red5_udp_nsg_ports]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "node_network_interface_security_association" {
  count                     = var.origin_image_create ? 1 : 0
  network_interface_id      = azurerm_network_interface.node_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.red5_node_network_security_group[0].id
}

################################################################################
# Stream Manager Network Configuration
################################################################################
resource "azurerm_public_ip" "sm_public_ip" {
  count               = local.cluster || local.autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-sm-public-ip"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "sm_network_interface" {
  count               = local.cluster || local.autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-sm-network-interface"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  ip_configuration {
    name                          = "${var.name}-${var.azure_region}-sm-ip-configuration"
    subnet_id                     = azurerm_subnet.vpc_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sm_public_ip[0].id
  }
}

resource "azurerm_network_security_group" "red5_stream_manager_network_security_group" {
  count               = local.cluster || local.autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-sm-nsg"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-sm-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.stream_manager_red5_nsg_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "sm_network_interface_security_association" {
  count                     = local.cluster || local.autoscaling ? 1 : 0
  network_interface_id      = azurerm_network_interface.sm_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.red5_stream_manager_network_security_group[0].id
}

################################################################################
# Red5 Pro Single server (Azure virtual Machine)
################################################################################
resource "azurerm_linux_virtual_machine" "red5_single" {
  count               = local.single ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-single-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.virtual_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.red5_single_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.red5pro_cloudstorage_postprocessor_enable}'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "nohup sudo -E /home/ubuntu/red5pro-installer/r5p_ssl_check_install.sh >> /home/ubuntu/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

################################################################################
# Red5 Pro Stream Manager  (Azure virtual Machine)
################################################################################
resource "azurerm_linux_virtual_machine" "red5_stream_manager" {
  count               = local.cluster || local.autoscaling ? 1 : 0 
  name                = "${var.name}-${var.azure_region}-red5-stream-manager-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.stream_manager_machine_size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.sm_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "file" {
    source      = var.path_to_azure_cloud_controller
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_azure_cloud_controller)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_API_KEY='${var.stream_manager_api_key}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_PREFIX_NAME='${var.name}-node'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      "export DB_LOCAL_ENABLE='${local.mysql_local_enable}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${var.mysql_port}'",
      "export DB_USER='${var.mysql_username}'",
      "export DB_PASSWORD='${nonsensitive(var.mysql_password)}'",
      "export AZURE_RESOURCE_GROUP='${local.az_resource_group}'",
      "export AZURE_REGION='${var.azure_region}'",
      "export AZURE_PREFIX_NAME='${var.name}'",
      "export AZURE_CLIENT_ID='${var.azure_client_id}'",
      "export AZURE_CLIENT_SECRET='${var.azure_client_secret}'",
      "export AZURE_TENANT_ID='${var.azure_tenant_id}'",
      "export AZURE_SUBSCRIPTION_ID='${var.azure_subscription_id}'",
      "export AZURE_VIRTUAL_MACHINE_PASSWORD='${var.azure_virtual_machine_password}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_mysql_local.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_stream_manager.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "nohup sudo -E /home/ubuntu/red5pro-installer/r5p_ssl_check_install.sh >> /home/ubuntu/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

  lifecycle {
    ignore_changes = all
  }

}

resource "null_resource" "dealocate_stream_manager_vm" {
  count      = local.autoscaling ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_stream_manager[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_stream_manager]
}

resource "null_resource" "generalize_stream_manager_vm" {
  count      = local.autoscaling ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm generalize -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_stream_manager[0].name}"
  }
    depends_on = [null_resource.dealocate_stream_manager_vm]
}


################################################################################
# Red5 Pro MySQL Database
################################################################################
resource "azurerm_mysql_server" "red5_database" {
  count               = local.mysql_db_system_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-mysql-server"
  location            = var.azure_region
  resource_group_name = local.az_resource_group

  administrator_login          = var.mysql_username
  administrator_login_password = var.mysql_password

  sku_name   = var.mysql_database_sku
  storage_mb = var.mysql_storage_mb
  version    = "8.0"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_firewall_rule" "red5_database_firewall_rule" {
  count               = local.mysql_db_system_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-mysql-firewall"
  resource_group_name = local.az_resource_group
  server_name         = azurerm_mysql_server.red5_database[0].name
  start_ip_address    = azurerm_public_ip.sm_public_ip[0].ip_address
  end_ip_address      = azurerm_public_ip.sm_public_ip[0].ip_address
}

resource "azurerm_mysql_virtual_network_rule" "mysql_network_rule" {
  count               = local.mysql_db_system_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-mysql-virtual-network-rule"
  resource_group_name = local.az_resource_group
  server_name         = azurerm_mysql_server.red5_database[0].name
  subnet_id           = azurerm_subnet.vpc_subnet[0].id
}
################################################################################
# Red5 Pro Load Balancer  (Azure Autoscale)
################################################################################
resource "azurerm_public_ip" "lb_ip" {
  count               = local.autoscaling ? 1 : 0
  name                = "${var.name}-lb-public-ip"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "red5_gateway" {
  count               = local.autoscaling ? 1 : 0
  name                = "${var.name}-aplication-gateway-lb"
  resource_group_name = local.az_resource_group
  location            = var.azure_region

  sku {
    name     = var.application_gateway_sku_name
    tier     = var.application_gateway_sku_tier
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.name}-lb-gateway-ip-config"
    subnet_id = azurerm_subnet.vpc_subnet[0].id
  }

  frontend_port {
    name = "${var.name}-lb-http-frontend-port"
    port = 5080
  }
  
  frontend_port {
    name = "${var.name}-lb-https-frontend-port"
    port = 443
  }

  ssl_certificate {
    name     = "${var.name}-lb-ssl-certificcate"
    data     = filebase64(var.ssl_certificate_pfx_path)
    password = var.ssl_certificate_pfx_password
  }

  frontend_ip_configuration {
    name                 = "${var.name}-lb-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.lb_ip[0].id
  }

  backend_address_pool {
    name = "${var.name}-lb-backend-pool"
  }

  backend_http_settings {
    name                  = "${var.name}-lb-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 5080
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${var.name}-lb-http-listener"
    frontend_ip_configuration_name = "${var.name}-lb-frontend-ip-config"
    frontend_port_name             = "${var.name}-lb-http-frontend-port"
    protocol                       = "Http"
  }
    http_listener {
    name                           = "${var.name}-lb-https-listener"
    frontend_ip_configuration_name = "${var.name}-lb-frontend-ip-config"
    frontend_port_name             = "${var.name}-lb-https-frontend-port"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.name}-lb-ssl-certificcate"
  }

  request_routing_rule {
    name                       = "${var.name}-lb-http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.name}-lb-http-listener"
    backend_address_pool_name  = "${var.name}-lb-backend-pool"
    backend_http_settings_name = "${var.name}-lb-http-settings"
    priority                   = 2
  }
  request_routing_rule {
    name                       = "${var.name}-lb-https-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.name}-lb-https-listener"
    backend_address_pool_name  = "${var.name}-lb-backend-pool"
    backend_http_settings_name = "${var.name}-lb-http-settings"
    priority                   = 1
  }
}
# Autoscaling Stream Manager
resource "azurerm_linux_virtual_machine_scale_set" "autoscale_sm" {
  count               = local.autoscaling ? 1 : 0
  name                = "${var.name}-vm-scale-set"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  sku                 = var.stream_manager_machine_size
  instances           = 1
  admin_username      = "ubuntu"
  source_image_id     = azurerm_image.stream_manager_image[0].id

  admin_ssh_key {
    username   = "ubuntu"
    public_key = local.public_ssh_key
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.name}-vm-scale-set-nic"
    primary = true

    ip_configuration {
      name      = "${var.name}-vm-scale-set-nic-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.vpc_subnet[0].id
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.red5_gateway[0].backend_address_pool[*].id

    }
  }
}

################################################################################
# Red5 Pro origin node  (Azure virtual Machine)
################################################################################
# Red5 Pro origin node 
resource "azurerm_linux_virtual_machine" "red5_origin" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-origin-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.origin_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.node_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.origin_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.origin_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.origin_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.origin_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.origin_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.origin_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.origin_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.origin_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.origin_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.origin_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.origin_red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.origin_red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.origin_red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.origin_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

# Dealocating Origin Image
resource "null_resource" "dealocate_origin_vm" {
  count      = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_origin[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_origin]
}

# Dealocating Origin Image
resource "null_resource" "generalize_origin_vm" {
  count      = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm generalize -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_origin[0].name}"
  }
    depends_on = [null_resource.dealocate_origin_vm]
}

# Red5 Pro edge node 
resource "azurerm_linux_virtual_machine" "red5_edge" {
  count               = var.edge_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-edge-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.edge_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.node_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.edge_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.edge_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.edge_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.edge_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.edge_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.edge_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.edge_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.edge_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.edge_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.edge_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.edge_red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.edge_red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.edge_red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.edge_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

# Red5 Pro transcoder node 
resource "azurerm_linux_virtual_machine" "red5_transcoder" {
  count               = var.transcoder_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-transcoder-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.transcoder_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.node_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.transcoder_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.transcoder_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.transcoder_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.transcoder_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.transcoder_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.transcoder_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.transcoder_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.transcoder_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.transcoder_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.transcoder_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.transcoder_red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.transcoder_red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.transcoder_red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.transcoder_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

# Red5 Pro relay node 
resource "azurerm_linux_virtual_machine" "red5_relay" {
  count               = var.relay_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-relay-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.relay_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.node_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = local.image_offer
    sku              = local.image_sku
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.relay_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.relay_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.relay_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.relay_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.relay_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.relay_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.relay_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.relay_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.relay_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.relay_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.relay_red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.relay_red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.relay_red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.relay_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

####################################################################################################
# Red5 Pro Autoscaling Nodes create images - Origin/Edge/Transcoders/Relay
####################################################################################################
# Stream Manager Image
resource "azurerm_image" "stream_manager_image" {
  count               = local.autoscaling ? 1 : 0
  name                = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}-${var.azure_region}-img"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  lifecycle {
    ignore_changes    = [ name ]
  }

  depends_on = [ null_resource.dealocate_stream_manager_vm,
                 null_resource.generalize_stream_manager_vm
               ]
}
# Origin Node - Origin Image
resource "azurerm_image" "origin_image" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-origin-image-${formatdate("DDMMMYY-hhmm", timestamp())}-${var.azure_region}-img"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_origin[0].id
  lifecycle {
    ignore_changes    = [ name ]
  }

  depends_on = [ null_resource.dealocate_origin_vm,
                 null_resource.generalize_origin_vm 
               ]
}
# Edge Node - Edge Image
resource "azurerm_image" "edge_image" {
  count               = var.edge_image_create ? 1 : 0
  name                = "${var.name}-edge-image-${formatdate("DDMMMYY-hhmm", timestamp())}-${var.azure_region}-img"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_edge[0].id
  lifecycle {
    ignore_changes    = [ name ]
  }
}
# Relay Node - Relay Image
resource "azurerm_image" "relay_image" {
  count               = var.relay_image_create ? 1 : 0
  name                = "${var.name}-relay-image-${formatdate("DDMMMYY-hhmm", timestamp())}-${var.azure_region}-img"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_relay[0].id
  lifecycle {
    ignore_changes    = [ name ]
  }
}
# Transcoder Node - Transcoder Image
resource "azurerm_image" "transcoder_image" {
  count               = var.transcoder_image_create ? 1 : 0
  name                = "${var.name}-transcoder-image-${formatdate("DDMMMYY-hhmm", timestamp())}-${var.azure_region}-img"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_transcoder[0].id
  lifecycle {
    ignore_changes    = [ name ]
  }
}

################################################################################
# Stop droplet which used for creating nodes(Origin, Edge, Transcoder, Relay) images (Azure CLI)
################################################################################
# Stop Origin node virtual machine Azure CLI
resource "null_resource" "stop_origin_node" {
  count      = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm delete --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_origin[0].name} --force-deletion none --yes"
  }
  depends_on = [ azurerm_image.origin_image ]
}
# Stop Edge node virtual machine Azure CLI
resource "null_resource" "stop_edge_node" {
  count      = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm delete --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_edge[0].name} --force-deletion none --yes"
  }
  depends_on = [ azurerm_image.edge_image ]
}
# Stop Relay node virtual machine Azure CLI
resource "null_resource" "stop_relay_node" {
  count      = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm delete --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_relay[0].name} --force-deletion none --yes"
  }
  depends_on = [ azurerm_image.relay_image ]
}
# Stop Origin node virtual machine Azure CLI
resource "null_resource" "stop_transcoder_node" {
  count      = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm delete --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_transcoder[0].name} --force-deletion none --yes"
  }
  depends_on = [ azurerm_image.transcoder_image ]
}

################################################################################
# Create node group (Stream Manager API)
################################################################################

resource "null_resource" "node_group" {
  count    = var.node_group_create ? 1 : 0
  triggers = {
    trigger_name  = "node-group-trigger"
    SM_IP  = "${local.stream_manager_ip}"
    SM_API_KEY = "${var.stream_manager_api_key}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.SM_API_KEY}'"
  }
  provisioner "local-exec" {
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      NAME                       = "${var.name}"
      SM_IP                      = "${local.stream_manager_ip}"
      SM_API_KEY                 = "${var.stream_manager_api_key}"
      NODE_GROUP_REGION          ="${var.azure_region}"
      NODE_GROUP_NAME            = "${var.node_group_name}"
      ORIGINS                    = "${var.node_group_origins}"
      EDGES                      = "${var.node_group_edges}"
      TRANSCODERS                = "${var.node_group_transcoders}"
      RELAYS                     = "${var.node_group_relays}"
      ORIGIN_MACHINE_SIZE        = "${var.node_group_origins_machine_size}"
      EDGE_MACHINE_SIZE          = "${var.node_group_edges_machine_size}"
      TRANSCODER_MACHINE_SIZE    = "${var.node_group_transcoders_machine_size}"
      RELAY_MACHINE_SIZE         = "${var.node_group_relays_machine_size}"
      ORIGIN_CAPACITY            = "${var.node_group_origins_capacity}"
      EDGE_CAPACITY              = "${var.node_group_edges_capacity}"
      TRANSCODER_CAPACITY        = "${var.node_group_transcoders_capacity}"
      RELAY_CAPACITY             = "${var.node_group_relays_capacity}"
      ORIGIN_IMAGE_NAME          = "${try(azurerm_image.origin_image[0].name, null)}"
      EDGE_IMAGE_NAME            = "${try(azurerm_image.edge_image[0].name, null)}"
      TRANSCODER_IMAGE_NAME      = "${try(azurerm_image.transcoder_image[0].name, null)}"
      RELAY_IMAGE_NAME           = "${try(azurerm_image.relay_image[0].name, null)}"
    }
  }

  depends_on =  [ azurerm_linux_virtual_machine.red5_stream_manager ]
}