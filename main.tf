locals {
  standalone                    = var.type == "standalone" ? true : false
  cluster                       = var.type == "cluster" ? true : false
  autoscale                     = var.type == "autoscale" ? true : false
  cluster_or_autoscale          = local.cluster || local.autoscale ? true : false
  ssh_private_key_path          = var.ssh_key_use_existing ? var.existing_private_ssh_key_path : local_file.red5pro_ssh_key_pem[0].filename
  az_resource_group_name        = var.azure_resource_group_use_existing ? var.existing_azure_resource_group_name : azurerm_resource_group.az_resource_group[0].name
  public_ssh_key                = var.ssh_key_use_existing ? file(var.existing_public_ssh_key_path) : tls_private_key.red5pro_ssh_key[0].public_key_openssh
  private_ssh_key               = var.ssh_key_use_existing ? file(var.existing_private_ssh_key_path) : tls_private_key.red5pro_ssh_key[0].private_key_pem
  stream_manager_ip             = local.autoscale ? azurerm_public_ip.lb_ip[0].ip_address : local.cluster ? azurerm_linux_virtual_machine.red5_stream_manager[0].public_ip_address : null
  standalone_server_ip          = local.standalone ? azurerm_linux_virtual_machine.red5_standalone[0].public_ip_address : null
  stream_manager_ssl            = local.cluster_or_autoscale ? var.https_ssl_certificate : null
  stream_manager_standalone     = local.autoscale ? false : true
  kafka_standalone_instance     = local.autoscale ? true : local.cluster && var.kafka_standalone_instance_create ? true : false
  kafka_ip                      = local.cluster_or_autoscale ? local.kafka_standalone_instance ? azurerm_linux_virtual_machine.red5_kafka_service[0].private_ip_address : azurerm_linux_virtual_machine.red5_stream_manager[0].private_ip_address : null
  kafka_on_sm_replicas          = local.kafka_standalone_instance ? 0 : 1
  kafka_ssl_keystore_key        = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", trimspace(tls_private_key.kafka_server_key[0].private_key_pem_pkcs8)))) : null
  kafka_ssl_truststore_cert     = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_self_signed_cert.ca_cert[0].cert_pem))) : null
  kafka_ssl_keystore_cert_chain = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_locally_signed_cert.kafka_server_cert[0].cert_pem))) : null
  vpc_name                      = azurerm_virtual_network.red5_vpc.name
  vpc_id                        = azurerm_virtual_network.red5_vpc.id
  security_group_name_node      = var.node_image_create ? azurerm_network_security_group.red5_node_network_security_group[0].name : null
  node_image_name               = var.node_image_create ? azurerm_image.node_image[0].name : null
  security_group_name_kafka     = local.autoscale ? azurerm_network_security_group.kafka_service_network_security_group[0].name : local.cluster && var.kafka_standalone_instance_create ? azurerm_network_security_group.kafka_service_network_security_group[0].name : null
  security_group_name_sm        = local.cluster_or_autoscale ? azurerm_network_security_group.stream_manager_network_security_group[0].name : null
  red5pro_node_image_name       = local.cluster_or_autoscale && var.node_image_create ? "${var.name}-node-image-${formatdate("DDMMMYY-hhmm", timestamp())}" : ""
}

################################################################################
# SSH_KEY
################################################################################
# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count               = var.ssh_key_use_existing ? 0 : 1
  algorithm           = "RSA"
  rsa_bits            = 4096
}

# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count               = var.ssh_key_use_existing ? 0 : 1
  filename            = "./${var.name}-ssh-key.pem"
  content             = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission     = "0400"
}

resource "local_file" "red5pro_ssh_key_pub" {
  count               = var.ssh_key_use_existing ? 0 : 1
  filename            = "./${var.name}-ssh-key.pub"
  content             = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

resource "azurerm_ssh_public_key" "red5pro_ssh" {
  count               = var.ssh_key_use_existing ? 0 : 1
  name                = "${var.name}-ssh-key-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  public_key          = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

################################################################################
# Azure Resource Group 
################################################################################
# Create a new resource group in azure account
resource "azurerm_resource_group" "az_resource_group" {
  count               = var.azure_resource_group_use_existing ? 0 : 1
  name                = "${var.name}-rg"
  location            = var.azure_region
}

data "azurerm_resources" "existing_az_resource" {
  count               = var.azure_resource_group_use_existing ? 1 : 0
  resource_group_name = var.existing_azure_resource_group_name
}

################################################################################
# VPC - Create new (VPC)
################################################################################
resource "azurerm_virtual_network" "red5_vpc" {
  name                = "${var.name}-vnet-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  address_space       = [var.vpc_cidr_block]
}

resource "azurerm_subnet" "vpc_subnet_default" {
  name                 = "default"
  resource_group_name  = local.az_resource_group_name
  virtual_network_name = azurerm_virtual_network.red5_vpc.name
  address_prefixes     = [cidrsubnet(var.vpc_cidr_block, 4, 0)]
}

################################################################################
# Red5 Pro Standalone Server Network Configuration
################################################################################
resource "azurerm_public_ip" "standalone_public-ip" {
  count               = local.standalone ? 1 : 0
  name                = "${var.name}-standalone-public-ip-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "red5_standalone_network_interface" {
  count               = local.standalone ? 1 : 0
  name                = "${var.name}-standalone-nic-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name

  ip_configuration {
    name                          = "${var.name}-standalone-ipconf-${var.azure_region}"
    subnet_id                     = azurerm_subnet.vpc_subnet_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.standalone_public-ip[0].id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "red5_network_standalone_security_group" {
  count               = local.standalone ? 1 : 0
  name                = "${var.name}-standalone-nsg-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  security_rule {
    name                       = "${var.name}-standalone-tcp-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.standalone_red5_nsg_tcp_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.name}-standalone-udp-rule"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = var.standalone_red5_nsg_udp_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "red5_standalone_network_interface_security_association" {
  count                     = local.standalone ? 1 : 0
  network_interface_id      = azurerm_network_interface.red5_standalone_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.red5_network_standalone_security_group[0].id
}

################################################################################
# Red5 Pro Node Network Configuration
################################################################################
resource "azurerm_public_ip" "node_public_ip" {
  count               = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name                = "${var.name}-node-public-ip-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "node_network_interface" {
  count               = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name                = "${var.name}-node-nic-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  ip_configuration {
    name                          = "${var.name}-node-ipconf-${var.azure_region}"
    subnet_id                     = azurerm_subnet.vpc_subnet_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node_public_ip[0].id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "red5_node_network_security_group" {
  count               = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name                = "${var.name}-node-nsg-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  security_rule {
    name                       = "${var.name}-node-tcp-nsg-rule"
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
    name                       = "${var.name}-node-udp-nsg-rule"
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
  count                     = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  network_interface_id      = azurerm_network_interface.node_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.red5_node_network_security_group[0].id
}

################################################################################
# Red5 Pro Kafka Service Network Configuration
################################################################################
resource "azurerm_public_ip" "kafka_service_public_ip" {
  count               = local.kafka_standalone_instance ? 1 : 0
  name                = "${var.name}-kafka-public-ip-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "kafka_service_network_interface" {
  count               = local.kafka_standalone_instance ? 1 : 0
  name                = "${var.name}-kafka-nic-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  ip_configuration {
    name                          = "${var.name}-kafka-ipconf-${var.azure_region}"
    subnet_id                     = azurerm_subnet.vpc_subnet_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kafka_service_public_ip[0].id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "kafka_service_network_security_group" {
  count               = local.kafka_standalone_instance ? 1 : 0
  name                = "${var.name}-kafka-nsg-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  security_rule {
    name                       = "${var.name}-kafka-tcp-nsg-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.kafka_service_tcp_nsg_ports
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "kafka_service_network_interface_security_association" {
  count                     = local.kafka_standalone_instance ? 1 : 0
  network_interface_id      = azurerm_network_interface.kafka_service_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.kafka_service_network_security_group[0].id
}

################################################################################
# Stream Manager Network Configuration
################################################################################
resource "azurerm_public_ip" "sm_public_ip" {
  count               = local.cluster_or_autoscale ? 1 : 0
  name                = "${var.name}-sm-public-ip-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  allocation_method   = "Static"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "sm_network_interface" {
  count               = local.cluster_or_autoscale ? 1 : 0
  name                = "${var.name}-sm-nic-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  ip_configuration {
    name                          = "${var.name}-sm-ipconf-${var.azure_region}"
    subnet_id                     = azurerm_subnet.vpc_subnet_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sm_public_ip[0].id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_security_group" "stream_manager_network_security_group" {
  count               = local.cluster_or_autoscale ? 1 : 0
  name                = "${var.name}-sm-nsg-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name
  security_rule {
    name                       = "${var.name}-sm-tcp-nsg-rule"
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
  count                     = local.cluster_or_autoscale ? 1 : 0
  network_interface_id      = azurerm_network_interface.sm_network_interface[0].id
  network_security_group_id = azurerm_network_security_group.stream_manager_network_security_group[0].id
}

################################################################################
# Red5 Pro Standalone server (Azure virtual Machine)
################################################################################
resource "random_password" "ssl_password_red5pro_standalone" {
  count   = local.standalone && var.https_ssl_certificate != "none" ? 1 : 0
  length  = 16
  special = false
}

resource "azurerm_linux_virtual_machine" "red5_standalone" {
  count               = local.standalone ? 1 : 0
  name                = "${var.name}-standalone-vm-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  size                = var.standalone_virtual_machine_size
  admin_username      = "ubuntu"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.red5_standalone_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.standalone_virtual_machine_storage_type
    disk_size_gb         = var.standalone_volume_size
    name                 = "${var.name}-standalone-disk"
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
      "export NODE_INSPECTOR_ENABLE='${var.standalone_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.standalone_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.standalone_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.standalone_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.standalone_red5pro_hls_enable}'",
      "export NODE_HLS_OUTPUT_FORMAT='${var.standalone_red5pro_hls_output_format}'",
      "export NODE_HLS_DVR_PLAYLIST='${var.standalone_red5pro_hls_dvr_playlist}'",
      "export NODE_WEBHOOKS_ENABLE='${var.standalone_red5pro_webhooks_enable}'",
      "export NODE_WEBHOOKS_ENDPOINT='${var.standalone_red5pro_webhooks_endpoint}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.standalone_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.standalone_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.standalone_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.standalone_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.standalone_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_NAME='${var.standalone_red5pro_azure_storage_account_name}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_KEY='${var.standalone_red5pro_azure_storage_account_key}'",
      "export NODE_CLOUDSTORAGE_AZURE_STORAGE_ACCOUNT_CONTAINER_NAME='${var.standalone_red5pro_azure_storage_container_name}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.standalone_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node_apps_plugins.sh",
       "sudo systemctl daemon-reload && sudo systemctl restart red5pro",
      "sudo mkdir -p /usr/local/red5pro/certs",
      "echo '${try(file(var.https_ssl_certificate_cert_path), "")}' | sudo tee -a /usr/local/red5pro/certs/fullchain.pem",
      "echo '${try(file(var.https_ssl_certificate_key_path), "")}' | sudo tee -a /usr/local/red5pro/certs/privkey.pem",
      "export SSL='${var.https_ssl_certificate}'",
      "export SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_ssl_certificate_email}'",
      "export SSL_PASSWORD='${try(nonsensitive(random_password.ssl_password_red5pro_standalone[0].result), "")}'",
      "export SSL_CERT_PATH=/usr/local/red5pro/certs",
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
  depends_on = [ azurerm_network_interface_security_group_association.red5_standalone_network_interface_security_association ]
}

################################################################################
# Red5 Pro Stream Manager  (Azure virtual Machine)
################################################################################
# Generate random password for Red5 Pro Stream Manager 2.0 authentication
resource "random_password" "r5as_auth_secret" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 32
  special = false
}

resource "azurerm_linux_virtual_machine" "red5_stream_manager" {
  count               = local.cluster_or_autoscale ? 1 : 0 
  name                = "${var.name}-sm-vm-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
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
    disk_size_gb         = var.stream_manager_volume_size
    name                 = "${var.name}-sm-disk" 
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
    version          = "latest"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    mkdir -p /usr/local/stream-manager/keys
    mkdir -p /usr/local/stream-manager/certs
    echo "${try(file(var.https_ssl_certificate_cert_path), "")}" > /usr/local/stream-manager/certs/cert.pem
    echo "${try(file(var.https_ssl_certificate_key_path), "")}" > /usr/local/stream-manager/certs/privkey.pem
    chmod 400 /usr/local/stream-manager/certs/privkey.pem
    ############################ .env file #########################################################
    cat >> /usr/local/stream-manager/.env <<- EOM
    KAFKA_CLUSTER_ID=${random_id.kafka_cluster_id[0].b64_std}
    KAFKA_ADMIN_USERNAME=${random_string.kafka_admin_username[0].result}
    KAFKA_ADMIN_PASSWORD=${random_id.kafka_admin_password[0].id}
    KAFKA_CLIENT_USERNAME=${random_string.kafka_client_username[0].result}
    KAFKA_CLIENT_PASSWORD=${random_id.kafka_client_password[0].id}
    R5AS_AUTH_SECRET=${random_password.r5as_auth_secret[0].result}
    R5AS_AUTH_USER=${var.stream_manager_auth_user}
    R5AS_AUTH_PASS=${var.stream_manager_auth_password}
    R5AS_PROXY_USER=${var.stream_manager_proxy_user}
    R5AS_PROXY_PASS=${var.stream_manager_proxy_password}
    R5AS_SPATIAL_USER=${var.stream_manager_spatial_user}
    R5AS_SPATIAL_PASS=${var.stream_manager_spatial_password}
    CONTAINER_REGISTRY=${var.stream_manager_container_registry}
    AS_VERSION=${var.stream_manager_version}
    AS_TESTBED_VERSION=${var.stream_manager_testbed_version}
    TF_VAR_azure_tenant_id=${var.azure_tenant_id}
    TF_VAR_azure_subscription_id=${var.azure_subscription_id}
    TF_VAR_azure_client_id=${var.azure_client_id}
    TF_VAR_azure_client_secret=${var.azure_client_secret}
    TF_VAR_azure_ssh_public_key=${local.public_ssh_key}
    TF_VAR_azure_ssh_username=ubuntu
    TF_VAR_azure_resource_group_name=${local.az_resource_group_name}
    TF_VAR_azure_storage_account_type=${var.node_machine_storage_type}
    TF_VAR_r5p_license_key=${var.red5pro_license_key}
    TRAEFIK_TLS_CHALLENGE=${local.stream_manager_ssl == "letsencrypt" ? "true" : "false"}
    TRAEFIK_SSL_EMAIL=${var.https_ssl_certificate_email}
    TRAEFIK_CMD=${local.stream_manager_ssl == "imported" ? "--providers.file.filename=/scripts/traefik.yaml" : ""}
  EOF
  )
}

resource "null_resource" "red5pro_sm_configuration" {
  triggers = {
    sm_id  = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  }
  count    = local.cluster_or_autoscale ? 1 : 0

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = azurerm_linux_virtual_machine.red5_stream_manager[0].public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }
  provisioner "remote-exec" {
    inline = [
      "until sudo cloud-init status | grep 'done'; do echo 'waiting for cloud-init'; sleep 10; done",
      "echo 'KAFKA_SSL_KEYSTORE_KEY=${local.kafka_ssl_keystore_key}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_TRUSTSTORE_CERTIFICATES=${local.kafka_ssl_truststore_cert}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_KEYSTORE_CERTIFICATE_CHAIN=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_REPLICAS=${local.kafka_on_sm_replicas}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_IP=${local.kafka_ip}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'TRAEFIK_IP=${local.stream_manager_ip}' | sudo tee -a /usr/local/stream-manager/.env", # Use only in Cluster deployment
      "echo 'TRAEFIK_HOST=${var.stream_manager_public_hostname}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'AS_ADMIN_UI_VERSION=${var.stream_manager_admin_ui_version}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'AS_ADMIN_UI_MAIN_REGION=${var.azure_region}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'AS_ADMIN_UI_NODE_IMAGE_NAME=${local.red5pro_node_image_name}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'AS_ADMIN_UI_AZURE_VPC=${local.vpc_name}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'AS_ADMIN_UI_AZURE_SECURITY_GROUP=${local.security_group_name_node}' | sudo tee -a /usr/local/stream-manager/.env",
      "export SM_SSL='${local.stream_manager_ssl}'",
      "export SM_STANDALONE='${local.stream_manager_standalone}'",
      "export SM_SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "export CONTAINER_REGISTRY='${var.stream_manager_container_registry}'",
      "export CONTAINER_REGISTRY_USER='${var.stream_manager_container_registry_user}'",
      "export CONTAINER_REGISTRY_PASSWORD='${var.stream_manager_container_registry_password}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_sm2_azure.sh",
    ]
    connection {
      host        = azurerm_linux_virtual_machine.red5_stream_manager[0].public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }

  }
  depends_on = [tls_cert_request.kafka_server_csr, azurerm_linux_virtual_machine.red5_stream_manager, null_resource.red5pro_kafka]
  lifecycle {
    precondition {
      condition     = var.stream_manager_public_hostname != ""
      error_message = "ERROR! Value in variable stream_manager_public_hostname must be a valid FQDN! Example: sm.example.com"
    }
  }
}

resource "azapi_resource_action" "stop_sm_vm" {
  count       = local.autoscale ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  method      = "POST"
  action      = "poweroff"
  depends_on  = [azurerm_linux_virtual_machine.red5_stream_manager, null_resource.red5pro_sm_configuration]
}

resource "azapi_resource_action" "deallocate_sm_vm" {
  count       = local.autoscale ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  action      = "deallocate"
  method      = "POST"

  depends_on  = [azapi_resource_action.stop_sm_vm]
}

resource "azapi_resource_action" "generalize_sm_vm" {
  count       = local.autoscale ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  action      = "generalize"
  method      = "POST"

  depends_on  = [azapi_resource_action.deallocate_sm_vm]
}

################################################################################
# Kafka keys and certificates
################################################################################
# Generate random admin usernames for Kafka cluster
resource "random_string" "kafka_admin_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random client usernames for Kafka cluster
resource "random_string" "kafka_client_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random IDs for Kafka cluster
resource "random_id" "kafka_cluster_id" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_admin_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_client_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Create private key for CA
resource "tls_private_key" "ca_private_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create private key for kafka server certificate 
resource "tls_private_key" "kafka_server_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create self-signed certificate for CA
resource "tls_self_signed_cert" "ca_cert" {
  count             = local.cluster_or_autoscale ? 1 : 0
  private_key_pem   = tls_private_key.ca_private_key[0].private_key_pem
  is_ca_certificate = true

  subject {
    country             = "US"
    common_name         = "Infrared5, Inc."
    organization        = "Red5"
    organizational_unit = "Red5 Root Certification Auhtority"
  }

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
  ]
}

# Create CSR for server certificate 
resource "tls_cert_request" "kafka_server_csr" {
  count           = local.cluster_or_autoscale ? 1 : 0
  private_key_pem = tls_private_key.kafka_server_key[0].private_key_pem
  ip_addresses    = [local.kafka_ip]
  dns_names       = ["kafka0"]

  subject {
    country             = "US"
    common_name         = "Kafka server"
    organization        = "Infrared5, Inc."
    organizational_unit = "Development"
  }
  depends_on = [azurerm_linux_virtual_machine.red5_stream_manager, azurerm_linux_virtual_machine.red5_kafka_service]
}

# Sign kafka server Certificate by Private CA 
resource "tls_locally_signed_cert" "kafka_server_cert" {
  count                 = local.cluster_or_autoscale ? 1 : 0
  cert_request_pem      = tls_cert_request.kafka_server_csr[0].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_private_key[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert[0].cert_pem
  validity_period_hours = 1 * 365 * 24

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}
################################################################################
# Red5 Pro Kafka Service  (Azure virtual Machine)
################################################################################
resource "azurerm_linux_virtual_machine" "red5_kafka_service" {
  count               = local.kafka_standalone_instance ? 1 : 0
  name                = "${var.name}-kafka-vm-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  size                = var.kafka_service_machine_size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.kafka_service_network_interface[0].id,
  ]

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.kafka_service_machine_storage_type
    disk_size_gb         = var.kafka_standalone_volume_size
    name                 = "${var.name}-kafka-disk" 
  }

  source_image_reference {
    publisher        = "Canonical"
    offer            = lookup(var.ubuntu_image_offer, var.ubuntu_version, "what?")
    sku              = lookup(var.ubuntu_image_sku, var.ubuntu_version, "what?")
    version          = "latest"
  }
}

resource "null_resource" "red5pro_kafka" {
  count = local.kafka_standalone_instance ? 1 : 0

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home/ubuntu"

    connection {
      host        = azurerm_linux_virtual_machine.red5_kafka_service[0].public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }

  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo netfilter-persistent save",
      "sudo cloud-init status --wait",
      "echo 'ssl.keystore.key=${local.kafka_ssl_keystore_key}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'ssl.truststore.certificates=${local.kafka_ssl_truststore_cert}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'ssl.keystore.certificate.chain=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'listener.name.broker.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'listener.name.controller.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "echo 'advertised.listeners=BROKER://${local.kafka_ip}:9092' | sudo tee -a /home/ubuntu/red5pro-installer/server.properties",
      "export KAFKA_ARCHIVE_URL='${var.kafka_standalone_instance_arhive_url}'",
      "export KAFKA_CLUSTER_ID='${random_id.kafka_cluster_id[0].b64_std}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_kafka_install.sh",
    ]
    connection {
      host        = azurerm_linux_virtual_machine.red5_kafka_service[0].public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }
  depends_on = [tls_cert_request.kafka_server_csr, azurerm_linux_virtual_machine.red5_kafka_service]
}

################################################################################
# SM Load Balancer  (Azure Autoscale)
################################################################################
resource "azurerm_public_ip" "lb_ip" {
  count               = local.autoscale ? 1 : 0
  name                = "${var.name}-lb-public-ip-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  allocation_method   = "Static"
  sku                 = "Standard"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_lb" "autoscale_sm_lb" {
  count               = local.autoscale ? 1 : 0
  name                = "${var.name}-sm-lb-${var.azure_region}"
  location            = var.azure_region
  resource_group_name = local.az_resource_group_name

  frontend_ip_configuration {
    name                 = "${var.name}-frontend-ipconf"
    public_ip_address_id = azurerm_public_ip.lb_ip[0].id
  }
  sku      = "Standard"
  sku_tier = "Regional"
}

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  count              = local.autoscale ? 1 : 0
  name               = "${var.name}-lb-backend"
  loadbalancer_id    = azurerm_lb.autoscale_sm_lb[0].id
  virtual_network_id = local.vpc_id
  synchronous_mode   = "Automatic"
}

resource "azurerm_lb_rule" "lb_http_rule" {
  count                          = local.autoscale ? 1 : 0
  name                           = "${var.name}-lb-http-rule"
  loadbalancer_id                = azurerm_lb.autoscale_sm_lb[0].id
  frontend_ip_configuration_name = azurerm_lb.autoscale_sm_lb[0].frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.lb_backend[0].id ]
}

resource "azurerm_lb_rule" "lb_https_rule" {
  count                          = local.autoscale ? var.https_ssl_certificate == "imported" ? 1 : 0 : 0
  name                           = "${var.name}-lb-https-rule"
  loadbalancer_id                = azurerm_lb.autoscale_sm_lb[0].id
  frontend_ip_configuration_name = azurerm_lb.autoscale_sm_lb[0].frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_ids       = [ azurerm_lb_backend_address_pool.lb_backend[0].id ]
}

# Autoscaling Stream Manager
resource "azurerm_linux_virtual_machine_scale_set" "autoscale_sm" {
  count               = local.autoscale ? 1 : 0
  name                = "${var.name}-sm-scale-set-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  sku                 = var.stream_manager_machine_size
  instances           = var.stream_manager_count
  admin_username      = "ubuntu"
  source_image_id     = azurerm_image.stream_manager_image[0].id

  admin_ssh_key {
    username          = "ubuntu"
    public_key        = local.public_ssh_key
  }

  os_disk {
    storage_account_type = var.stream_manager_machine_storage_type
    caching              = "ReadWrite"
    disk_size_gb         = var.stream_manager_volume_size 
  }

  network_interface {
    name                      = "${var.name}-scale-set-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.stream_manager_network_security_group[0].id

    ip_configuration {
      name                                   = "${var.name}-scale-set-ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.vpc_subnet_default.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend[0].id]
      
      public_ip_address {
        name  = "${var.name}-scale-set-ip"
      }
    }
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    HOSTNAME=$(hostname)
    INSTANCE_NUMBER=$(echo $HOSTNAME | sed 's/.*set//')
    # Append the R5AS_GROUP_INSTANCE_ID to the .env file
    echo "R5AS_GROUP_INSTANCE_ID=$INSTANCE_NUMBER" >> /usr/local/stream-manager/.env
    # Start SM2.0 service
    systemctl enable sm.service
    systemctl start sm.service
  EOF
  )
}

################################################################################
# Red5 Pro node  (Azure virtual Machine)
################################################################################
# Red5 Pro node 
resource "azurerm_linux_virtual_machine" "red5_node" {
count                 = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name                = "${var.name}-node-vm-${var.azure_region}"
  resource_group_name = local.az_resource_group_name
  location            = var.azure_region
  size                = var.node_machine_size
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
    storage_account_type = var.node_machine_storage_type
    disk_size_gb         = var.node_image_volume_size
    name                 = "${var.name}-node-disk" 
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
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "cd /home/ubuntu/red5pro-installer/",
      "sudo chmod +x /home/ubuntu/red5pro-installer/*.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/ubuntu/red5pro-installer/r5p_config_node.sh",
    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "ubuntu"
      private_key = local.private_ssh_key
    }
  }

}

resource "azapi_resource_action" "stop_node_vm" {
  count       = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_node[0].id
  method      = "POST"
  action      = "poweroff"
  depends_on  = [azurerm_linux_virtual_machine.red5_node]
}

resource "azapi_resource_action" "deallocate_node_vm" {
  count       = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_node[0].id
  action      = "deallocate"
  method      = "POST"

  depends_on  = [azapi_resource_action.stop_node_vm]
}

resource "azapi_resource_action" "generalize_node_vm" {
  count       = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  type        = "Microsoft.Compute/virtualMachines@2023-03-01"
  resource_id = azurerm_linux_virtual_machine.red5_node[0].id
  action      = "generalize"
  method      = "POST"

  depends_on  = [azapi_resource_action.deallocate_node_vm]
}

####################################################################################################
# Red5 Pro Autoscaling create images - StreamManager/Node
####################################################################################################
# Stream Manager Image
resource "azurerm_image" "stream_manager_image" {
  count                     = local.autoscale ? 1 : 0
  name                      = "${var.name}-sm-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  location                  = var.azure_region
  resource_group_name       = local.az_resource_group_name
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_stream_manager[0].id
  
  lifecycle {
    ignore_changes = [ name ]
  }

  depends_on = [ azapi_resource_action.deallocate_sm_vm,
                 azapi_resource_action.generalize_sm_vm ]
}
# Node Image
resource "azurerm_image" "node_image" {
  count                     = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name                      = local.red5pro_node_image_name
  location                  = var.azure_region
  resource_group_name       = local.az_resource_group_name
  source_virtual_machine_id = azurerm_linux_virtual_machine.red5_node[0].id
  
  lifecycle {
    ignore_changes = [ name ]
  }

  depends_on = [ azapi_resource_action.deallocate_node_vm,
                 azapi_resource_action.generalize_node_vm ]
}

################################################################################
# Create/Delete node group (Stream Manager API)
################################################################################
resource "time_sleep" "wait_for_delete_nodegroup" {
  count      = var.node_group_create ? 1 : 0
  depends_on = [
    azurerm_linux_virtual_machine.red5_stream_manager,
    azurerm_network_interface_security_group_association.sm_network_interface_security_association,
    azurerm_network_security_group.stream_manager_network_security_group,
    azurerm_lb.autoscale_sm_lb,
    azurerm_lb_backend_address_pool.lb_backend,
    azurerm_lb_rule.lb_http_rule,
    azurerm_lb_rule.lb_https_rule,
    azurerm_linux_virtual_machine_scale_set.autoscale_sm,
    azurerm_network_interface.node_network_interface,
    azurerm_network_interface.sm_network_interface,
    azurerm_network_security_group.red5_node_network_security_group,
    azurerm_network_interface_security_group_association.node_network_interface_security_association,
    azurerm_linux_virtual_machine.red5_kafka_service,
    azurerm_network_interface.kafka_service_network_interface,
    azurerm_network_security_group.kafka_service_network_security_group,
    azurerm_network_interface_security_group_association.kafka_service_network_interface_security_association,
  ]
  
  destroy_duration = "2m"
}

resource "null_resource" "node_group" {
  count            = local.cluster_or_autoscale && var.node_group_create ? 1 : 0
  triggers = {
    trigger_name   = "node-group-trigger"
    SM_IP          = "${local.stream_manager_ip}"
    R5AS_AUTH_USER = "${var.stream_manager_auth_user}"
    R5AS_AUTH_PASS = "${var.stream_manager_auth_password}"
  }
  provisioner "local-exec" {
    when        = create
    command     = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      SM_IP                                          = "${local.stream_manager_ip}"
      NODE_GROUP_NAME                                = "${substr(var.name, 0, 16)}"
      R5AS_AUTH_USER                                 = "${var.stream_manager_auth_user}"
      R5AS_AUTH_PASS                                 = "${var.stream_manager_auth_password}"
      NODE_GROUP_CLOUD_PLATFORM                      = "AZURE"
      NODE_GROUP_REGIONS                             = "${var.azure_region}"
      NODE_GROUP_ENVIRONMENT                         = "${var.name}"
      NODE_GROUP_VPC_NAME                            = "${local.vpc_name}"
      NODE_GROUP_SECURITY_GROUP_NAME                 = "${local.security_group_name_node}"
      NODE_GROUP_IMAGE_NAME                          = "${local.node_image_name}"
      NODE_GROUP_ORIGINS_MIN                         = "${var.node_group_origins_min}"
      NODE_GROUP_ORIGINS_MAX                         = "${var.node_group_origins_max}"
      NODE_GROUP_ORIGIN_INSTANCE_TYPE                = "${var.node_group_origins_machine_size}"
      NODE_GROUP_ORIGIN_VOLUME_SIZE                  = "${var.node_group_origins_volume_size}"
      NODE_GROUP_ORIGINS_CONNECTION_LIMIT            = "${var.node_group_origins_connection_limit}"
      NODE_GROUP_EDGES_MIN                           = "${var.node_group_edges_min}"
      NODE_GROUP_EDGES_MAX                           = "${var.node_group_edges_max}"
      NODE_GROUP_EDGE_INSTANCE_TYPE                  = "${var.node_group_edges_machine_size}"
      NODE_GROUP_EDGE_VOLUME_SIZE                    = "${var.node_group_edges_volume_size}"
      NODE_GROUP_EDGES_CONNECTION_LIMIT              = "${var.node_group_edges_connection_limit}"
      NODE_GROUP_TRANSCODERS_MIN                     = "${var.node_group_transcoders_min}"
      NODE_GROUP_TRANSCODERS_MAX                     = "${var.node_group_transcoders_max}"
      NODE_GROUP_TRANSCODER_INSTANCE_TYPE            = "${var.node_group_transcoders_machine_size}"
      NODE_GROUP_TRANSCODER_VOLUME_SIZE              = "${var.node_group_transcoders_volume_size}"
      NODE_GROUP_TRANSCODERS_CONNECTION_LIMIT        = "${var.node_group_transcoders_connection_limit}"
      NODE_GROUP_RELAYS_MIN                          = "${var.node_group_relays_min}"
      NODE_GROUP_RELAYS_MAX                          = "${var.node_group_relays_max}"
      NODE_GROUP_RELAY_INSTANCE_TYPE                 = "${var.node_group_relays_machine_size}"
      NODE_GROUP_RELAY_VOLUME_SIZE                   = "${var.node_group_relays_volume_size}"
      NODE_GROUP_ROUND_TRIP_AUTH_ENABLE              = "${var.node_config_round_trip_auth.enable}"
      NODE_GROUP_ROUNT_TRIP_AUTH_TARGET_NODES        = "${join(",", var.node_config_round_trip_auth.target_nodes)}"
      NODE_GROUP_ROUND_TRIP_AUTH_HOST                = "${var.node_config_round_trip_auth.auth_host}"
      NODE_GROUP_ROUND_TRIP_AUTH_PORT                = "${var.node_config_round_trip_auth.auth_port}"
      NODE_GROUP_ROUND_TRIP_AUTH_PROTOCOL            = "${var.node_config_round_trip_auth.auth_protocol}"
      NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE   = "${var.node_config_round_trip_auth.auth_endpoint_validate}"
      NODE_GROUP_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE = "${var.node_config_round_trip_auth.auth_endpoint_invalidate}"
      NODE_GROUP_WEBHOOK_ENABLE                      = "${var.node_config_webhooks.enable}"
      NODE_GROUP_WEBHOOK_TARGET_NODES                = "${join(",", var.node_config_webhooks.target_nodes)}"
      NODE_GROUP_WEBHOOK_ENDPOINT                    = "${var.node_config_webhooks.webhook_endpoint}"
      NODE_GROUP_SOCIAL_PUSHER_ENABLE                = "${var.node_config_social_pusher.enable}"
      NODE_GROUP_SOCIAL_PUSHER_TARGET_NODES          = "${join(",", var.node_config_social_pusher.target_nodes)}"
      NODE_GROUP_RESTREAMER_ENABLE                   = "${var.node_config_restreamer.enable}"
      NODE_GROUP_RESTREAMER_TARGET_NODES             = "${join(",", var.node_config_restreamer.target_nodes)}"
      NODE_GROUP_RESTREAMER_TSINGEST                 = "${var.node_config_restreamer.restreamer_tsingest}"
      NODE_GROUP_RESTREAMER_IPCAM                    = "${var.node_config_restreamer.restreamer_ipcam}"
      NODE_GROUP_RESTREAMER_WHIP                     = "${var.node_config_restreamer.restreamer_whip}"
      NODE_GROUP_RESTREAMER_SRTINGEST                = "${var.node_config_restreamer.restreamer_srtingest}"
    }
  }
  provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.R5AS_AUTH_USER}' '${self.triggers.R5AS_AUTH_PASS}'"
  }

  depends_on = [time_sleep.wait_for_delete_nodegroup[0]]

  lifecycle {
    precondition {
      condition     = var.node_image_create == true
      error_message = "ERROR! Node group creation requires the creation of a Node image for the node group. Please set the 'node_image_create' variable to 'true' and re-run the Terraform apply."
    }
  }
}
