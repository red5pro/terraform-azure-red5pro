locals {
  single                               = var.type == "single" ? true : false
  cluster                              = var.type == "cluster" ? true : false
  autoscaling                          = var.type == "autoscaling" ? true : false
  ssh_private_key_path                 = var.create_new_ssh_keys ? local_file.red5pro_ssh_key_pem[0].filename : var.existing_private_ssh_key_path
  az_resource_group                    = var.create_azure_resource_group ? azurerm_resource_group.az_resource_group[0].name : var.existing_azure_resource_group_name
  resource_group_name_autoscaling      = var.create_azure_resource_group ? split("-${var.azure_region}", azurerm_resource_group.az_resource_group[0].name )[0] : split("-${var.azure_region}", var.existing_azure_resource_group_name)[0]
  public_ssh_key                       = var.create_new_ssh_keys ? tls_private_key.red5pro_ssh_key[0].public_key_openssh : file(var.existing_public_ssh_key_path)
  private_ssh_key                      = var.create_new_ssh_keys ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.existing_private_ssh_key_path)
  stream_manager_ip                    = local.autoscaling ? azurerm_public_ip.lb_ip[0].ip_address : local.cluster ? azurerm_linux_virtual_machine.red5_stream_manager[0].public_ip_address : null
  mysql_local_enable                   = local.autoscaling ? false : local.cluster && var.mysql_database_create ? false : local.cluster && var.terraform_service_instance_create ? false : true
  mysql_host                           = local.autoscaling ? azurerm_mysql_flexible_server.red5_database[0].fqdn : local.cluster && var.mysql_database_create ? azurerm_mysql_flexible_server.red5_database[0].fqdn : local.cluster && var.terraform_service_instance_create ? azurerm_mysql_flexible_server.red5_database[0].fqdn : "localhost"
  mysql_username                       = local.autoscaling ? var.mysql_username : local.cluster && var.mysql_database_create ? var.mysql_username : local.cluster && var.terraform_service_instance_create ? var.mysql_username : "localhost"
  mysql_db_system_create               = local.autoscaling ? true : local.cluster && var.mysql_database_create ? true : local.cluster && var.terraform_service_instance_create ? true : false
  single_server_ip                     = local.single ? azurerm_linux_virtual_machine.red5_single[0].public_ip_address : null
  cluster_or_autoscaling               = local.cluster || local.autoscaling ? true : false
  dedicated_terraform_service_create   = local.autoscaling ? true : local.cluster && var.terraform_service_instance_create ? true : false
  terraform_service_local_enable       = local.autoscaling ? false : local.cluster && var.terraform_service_instance_create ? false : true
  terraform_service_ip                 = local.autoscaling ? azurerm_linux_virtual_machine.red5_terraform_service[0].public_ip_address : local.cluster && var.terraform_service_instance_create ? azurerm_linux_virtual_machine.red5_terraform_service[0].public_ip_address : "localhost"
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

################################################################################
# Azure Resource Group 
################################################################################
# Create a new resource group in azure account
resource "azurerm_resource_group" "az_resource_group" {
  count               = var.create_azure_resource_group ? 1 : 0
  name                = "${var.new_azure_resource_group_name}-${var.azure_region}"
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
  name                = "${var.name}-${var.azure_region}-vnet"
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
  service_endpoints    = ["Microsoft.Sql"]
  delegation {
    name = "Microsoft.DBforMySQL/flexibleServers"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
    }
  }
  lifecycle {
    ignore_changes = [ delegation ]
  }
}

resource "azurerm_subnet" "vpc_subnet_default" {
  count                = local.cluster_or_autoscaling ? 1 : 0
  name                 = "default"
  resource_group_name  = local.az_resource_group
  virtual_network_name = azurerm_virtual_network.red5_vpc[0].name
  address_prefixes     = [cidrsubnets(var.vpc_cidr_block, 4, 4)[count.index+1]]
}

resource "azurerm_subnet" "application_gateway_subnet_default" {
  count                = local.cluster_or_autoscaling ? 1 : 0
  name                 = "${var.name}-${var.azure_region}-red5-application-gateway-subnet"
  resource_group_name  = local.az_resource_group
  virtual_network_name = azurerm_virtual_network.red5_vpc[0].name
  address_prefixes     = [cidrsubnets(var.vpc_cidr_block, 4, 4, 4)[count.index+2]]
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
    subnet_id                     = azurerm_subnet.vpc_subnet_default[0].id
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

resource "azurerm_network_interface_security_group_association" "red5_single_network_interface_security_association" {
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
    subnet_id                     = azurerm_subnet.vpc_subnet_default[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node_public_ip[0].id
  }
}

resource "azurerm_network_security_group" "red5_node_network_security_group" {
  count               = var.origin_image_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-nsg-node"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-node-tcp-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.node_red5_tcp_nsg_ports
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
    destination_port_ranges    = [var.node_red5_udp_nsg_ports]
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
# Red5 Pro Terraform Service Network Configuration
################################################################################
resource "azurerm_public_ip" "terraform_service_public_ip" {
  count               = local.dedicated_terraform_service_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-terraform-service-public-ip"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "terraform_service_network_interface" {
  count               = local.dedicated_terraform_service_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-terraform-service-network-interface"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  ip_configuration {
    name                          = "${var.name}-${var.azure_region}-terraform-service-ip-configuration"
    subnet_id                     = azurerm_subnet.vpc_subnet_default[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform_service_public_ip[0].id
  }
}

resource "azurerm_network_security_group" "terraform_service_network_security_group" {
  count               = local.dedicated_terraform_service_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-terraform-service-nsg"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-terraform-service-tcp-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.terraform_service_tcp_nsg_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "terraform_service_network_interface_security_association" {
  count                     = local.dedicated_terraform_service_create ? 1 : 0
  network_interface_id      = azurerm_network_interface.terraform_service_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.terraform_service_network_security_group[0].id
}

################################################################################
# Stream Manager Network Configuration
################################################################################
resource "azurerm_public_ip" "sm_public_ip" {
  count               = local.cluster_or_autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-sm-public-ip"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "sm_network_interface" {
  count               = local.cluster_or_autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-sm-network-interface"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  ip_configuration {
    name                          = "${var.name}-${var.azure_region}-sm-ip-configuration"
    subnet_id                     = azurerm_subnet.vpc_subnet_default[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sm_public_ip[0].id
  }
}

resource "azurerm_network_security_group" "red5_stream_manager_network_security_group" {
  count               = local.cluster_or_autoscaling ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-sm-nsg"
  location            = var.azure_region
  resource_group_name = local.az_resource_group
  security_rule {
    name                       = "${var.name}-${var.azure_region}-red5-sm-nsg-tcp-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.stream_manager_red5_nsg_tcp_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "sm_network_interface_security_association" {
  count                     = local.cluster_or_autoscaling ? 1 : 0
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
    storage_account_type = var.virtual_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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
  count               = local.cluster_or_autoscaling ? 1 : 0 
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
    storage_account_type = var.stream_manager_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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
    source      = var.path_to_terraform_service_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_terraform_service_build)}"
  }

  provisioner "file" {
    source      = var.path_to_terraform_cloud_controller
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_terraform_cloud_controller)}"
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
      "export DB_USER='${local.mysql_username}'",
      "export DB_PASSWORD='${nonsensitive(var.mysql_password)}'",
      "export TF_SVC_ENABLE='${local.terraform_service_local_enable}'",
      "export TERRA_HOST='${local.terraform_service_ip}'",
      "export TERRA_API_KEY='${var.terraform_service_api_key}'",
      "export TERRA_PARALLELISM='${var.terraform_service_parallelism}'",
      "export AZURE_RESOURCE_GROUP='${local.resource_group_name_autoscaling}'",
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
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_terraform_svc.sh",
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
# Red5 Pro Terraform Service  (Azure virtual Machine)
################################################################################
resource "azurerm_linux_virtual_machine" "red5_terraform_service" {
  count               = local.dedicated_terraform_service_create ? 1 : 0 
  name                = "${var.name}-${var.azure_region}-red5-terraform-service-vm"
  resource_group_name = local.az_resource_group
  location            = var.azure_region
  size                = var.terraform_service_machine_size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.terraform_service_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.terraform_service_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
    version          = "latest"
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu/"
  }

  provisioner "file" {
    source      = var.path_to_terraform_service_build
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_terraform_service_build)}"
  }

  provisioner "file" {
    source      = var.path_to_terraform_cloud_controller
    destination = "/home/ubuntu/red5pro-installer/${basename(var.path_to_terraform_cloud_controller)}"
  }

  connection {
    host        = self.public_ip_address
    type        = "ssh"
    user        = "ubuntu"
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo cloud-init status --wait",
      "export TF_SVC_ENABLE=true",
      "export AZURE_RESOURCE_GROUP='${local.resource_group_name_autoscaling}'",
      "export AZURE_PREFIX_NAME='${var.name}'",
      "export AZURE_CLIENT_ID='${var.azure_client_id}'",
      "export AZURE_CLIENT_SECRET='${var.azure_client_secret}'",
      "export AZURE_TENANT_ID='${var.azure_tenant_id}'",
      "export AZURE_SUBSCRIPTION_ID='${var.azure_subscription_id}'",
      "export AZURE_VIRTUAL_MACHINE_PASSWORD='${var.azure_virtual_machine_password}'",
      "export TERRA_API_KEY='${var.terraform_service_api_key}'",
      "export TERRA_PARALLELISM='${var.terraform_service_parallelism}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${var.mysql_port}'",
      "export DB_USER='${local.mysql_username}'",
      "export DB_PASSWORD='${nonsensitive(var.mysql_password)}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_terraform_svc.sh",
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
# Red5 Pro MySQL Database
################################################################################
resource "azurerm_mysql_flexible_server" "red5_database" {
  count               = local.mysql_db_system_create ? 1 : 0
  name                = "${var.name}-${var.azure_region}-red5-mysql-server"
  location            = var.azure_region
  resource_group_name = local.az_resource_group

  administrator_login          = var.mysql_username
  administrator_password       = var.mysql_password

  sku_name            = var.mysql_database_sku
  storage {
    size_gb           = var.mysql_storage_mb
    auto_grow_enabled = true
  }
  version                           = "8.0.21"
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  delegated_subnet_id               = azurerm_subnet.vpc_subnet[0].id
  lifecycle {
    ignore_changes = [ high_availability[0].standby_availability_zone, zone ]
  }
  depends_on = [ azurerm_subnet.vpc_subnet_default ]
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
    capacity = var.application_gateway_sku_capacity
  }

  gateway_ip_configuration {
    name      = "${var.name}-lb-gateway-ip-config"
    subnet_id = azurerm_subnet.application_gateway_subnet_default[0].id
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
    storage_account_type = var.stream_manager_machine_storage_type
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.name}-vm-scale-set-nic"
    primary = true

    ip_configuration {
      name      = "${var.name}-vm-scale-set-nic-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.vpc_subnet_default[0].id
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
    storage_account_type = var.origin_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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

# Dealocating Origin VM
resource "null_resource" "dealocate_origin_vm" {
  count      = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_origin[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_origin]
}

# Generalize Origin VM
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
    storage_account_type = var.edge_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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

# Dealocating Edge VM
resource "null_resource" "dealocate_edge_vm" {
  count      = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_edge[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_edge]
}

# Generalize Edge VM
resource "null_resource" "generalize_edge_vm" {
  count      = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm generalize -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_edge[0].name}"
  }
    depends_on = [null_resource.dealocate_edge_vm]
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
    storage_account_type = var.transcoder_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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

# Dealocating Transcoder VM
resource "null_resource" "dealocate_transcoder_vm" {
  count      = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_transcoder[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_transcoder]
}

# Generalize Transcoder VM
resource "null_resource" "generalize_transcoder_vm" {
  count      = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm generalize -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_transcoder[0].name}"
  }
    depends_on = [null_resource.dealocate_transcoder_vm]
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
    storage_account_type = var.relay_machine_storage_type
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
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

# Dealocating Relay VM
resource "null_resource" "dealocate_relay_vm" {
  count      = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm deallocate -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_relay[0].name}"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_relay]
}

# Generalize Relay VM
resource "null_resource" "generalize_relay_vm" {
  count      = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm generalize -g ${local.az_resource_group} -n ${azurerm_linux_virtual_machine.red5_relay[0].name}"
  }
    depends_on = [null_resource.dealocate_relay_vm]
}

####################################################################################################
# Red5 Pro Autoscaling Nodes create images - Origin/Edge/Transcoders/Relay
####################################################################################################
# Stream Manager Image
resource "azurerm_image" "stream_manager_image" {
  count               = local.autoscaling ? 1 : 0
  name                = "${var.name}-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
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

  depends_on = [ null_resource.dealocate_edge_vm,
                 null_resource.generalize_edge_vm 
               ]
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

  depends_on = [ null_resource.dealocate_relay_vm,
                null_resource.generalize_relay_vm 
               ]
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

  depends_on = [ null_resource.dealocate_transcoder_vm,
                null_resource.generalize_transcoder_vm 
               ]
}

################################################################################
# Stop droplet which used for creating nodes(Origin, Edge, Transcoder, Relay) images (Azure CLI)
################################################################################
# Stop Origin node virtual machine Azure CLI
resource "null_resource" "stop_origin_node" {
  count      = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm stop --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_origin[0].name} --subscription ${var.azure_subscription_id} --skip-shutdown"
  }
  depends_on = [ azurerm_image.origin_image ]
}
# Stop Edge node virtual machine Azure CLI
resource "null_resource" "stop_edge_node" {
  count      = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm stop --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_edge[0].name} --subscription ${var.azure_subscription_id} --skip-shutdown"
  }
  depends_on = [ azurerm_image.edge_image ]
}
# Stop Relay node virtual machine Azure CLI
resource "null_resource" "stop_relay_node" {
  count      = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm stop --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_relay[0].name} --subscription ${var.azure_subscription_id} --skip-shutdown"
  }
  depends_on = [ azurerm_image.relay_image ]
}
# Stop Origin node virtual machine Azure CLI
resource "null_resource" "stop_transcoder_node" {
  count      = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command  = "az vm stop --resource-group ${local.az_resource_group} --name ${azurerm_linux_virtual_machine.red5_transcoder[0].name} --subscription ${var.azure_subscription_id} --skip-shutdown"
  }
  depends_on = [ azurerm_image.transcoder_image ]
}

################################################################################
# Create/Delete node group (Stream Manager API)
################################################################################
resource "time_sleep" "wait_for_delete_nodegroup" {
  count      = var.node_group_create ? 1 : 0
  depends_on = [
    azurerm_linux_virtual_machine.red5_stream_manager[0],
    azurerm_mysql_flexible_server.red5_database[0],
    azurerm_network_interface_security_group_association.sm_network_interface_security_association[0],
    azurerm_network_security_group.red5_stream_manager_network_security_group[0],
    azurerm_mysql_flexible_server.red5_database[0],
    azurerm_application_gateway.red5_gateway[0],
    azurerm_linux_virtual_machine_scale_set.autoscale_sm[0],
    azurerm_network_interface.node_network_interface[0],
    azurerm_network_interface.sm_network_interface[0],
    azurerm_network_security_group.red5_node_network_security_group[0],
    azurerm_network_interface_security_group_association.node_network_interface_security_association[0],
    azurerm_linux_virtual_machine.red5_terraform_service[0],
    azurerm_network_interface.terraform_service_network_interface[0],
    azurerm_network_security_group.terraform_service_network_security_group[0],
    azurerm_network_interface_security_group_association.terraform_service_network_interface_security_association[0],
  ]
  
  destroy_duration = "2m"
}

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
      ORIGINS_MIN                = "${var.node_group_origins_min}"
      EDGES_MIN                  = "${var.node_group_edges_min}"
      TRANSCODERS_MIN            = "${var.node_group_transcoders_min}"
      RELAYS_MIN                 = "${var.node_group_relays_min}"
      ORIGINS_MAX                = "${var.node_group_origins_max}"
      EDGES_MAX                  = "${var.node_group_edges_max}"
      TRANSCODERS_MAX            = "${var.node_group_transcoders_max}"
      RELAYS_MAX                 = "${var.node_group_relays_max}"
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

  depends_on =  [ time_sleep.wait_for_delete_nodegroup[0] ]
}
