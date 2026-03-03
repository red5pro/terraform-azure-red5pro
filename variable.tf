variable "name" {
  description     = "Name to be used on all the resources as identifier"
  type            = string
  default         = ""
  validation {
    condition     = length(var.name) > 0
    error_message = "The name value must be a valid! Example: example-name"
  }
}

variable "type" {
  description     = "Type of deployment: standalone, cluster, autoscale"
  type            = string
  default         = "standalone"
  validation {
    condition     = var.type == "standalone" || var.type == "cluster" || var.type == "autoscale"
    error_message = "The type value must be a valid! Example: standalone, cluster, autoscale"
  }
}
variable "ubuntu_image_offer" {
  description     = "Ubuntu version to be used for the machines."
  type            = map(string)
  default = {
    "20.04"       = "0001-com-ubuntu-server-focal"
    "22.04"       = "0001-com-ubuntu-server-jammy"
  }
}

variable "ubuntu_image_sku" {
  description     = "Ubuntu version to be used for the machines."
  type            = map(string)
  default = {
    "20.04"       = "20_04-lts"
    "22.04"       = "22_04-lts"
  }
}

variable "ubuntu_version" {
  description     = "Ubuntu version which is going to be used for creating machine in Azure"
  type            = string
  default         = "22.04"
  validation {
    condition     = var.ubuntu_version == "20.04" || var.ubuntu_version == "22.04"
    error_message = "Please specify the correct ubuntu version, it can either be 20.04 or 22.04"
  }
}

variable "path_to_red5pro_build" {
  description     = "Path to the Red5 Pro build zip file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/red5pro-server-0.0.0.b0-release.zip"
  type            = string
  default         = ""
  validation {
    condition     = fileexists(var.path_to_red5pro_build) == true
    error_message = "The path_to_red5pro_build value must be a valid! Example: /home/ubuntu/red5pro-server-0.0.0.b0-release.zip"
  }
}

# Microsoft Azure account configuration
variable "azure_subscription_id" {
  description     = "Subscription ID of the Azure account"
  type            = string
  default         = ""
}
variable "azure_tenant_id" {
  description     = "Tenant ID of the Azure account"
  type            = string
  default         = ""
}
variable "azure_client_id" {
  description     = "Client ID of azure account"
  type            = string
  default         = ""
}
variable "azure_client_secret" {
  description     = "Client secret of the azure account"
  type            = string
  default         = ""
}

variable "azure_resource_group_use_existing" {
  description     = "Use existing azure resource group name where new resources will be created"
  type            = bool
  default         = true
}
variable "existing_azure_resource_group_name" {
  description     = "Use the already created resource group of azure account where all the resources will be created"
  type            = string
  default         = ""
}
variable "azure_region" {
  description     = "Region in azure account which is used to create the resources"
  type            = string
  default         = ""
}

# VPC configuration
variable "vpc_cidr_block" {
  description     = "VPC IP range for Red5 Pro"
  type            = string
  default         = "10.0.0.0/16"
}

# SSH keys Configuration
variable "ssh_key_use_existing" {
  description     = "Use existing SSH key pair or create a new one. true = use existing, false = create new"
  type            = bool
  default         = false
}
variable "existing_public_ssh_key_path" {
  description     = "Already created public SSH key path"
  type            = string
  default         = ""
}
variable "existing_private_ssh_key_path" {
  description     = "Already created private SSH key path"
  type            = string
  default         = ""
}

# Standalone server configuration
variable "standalone_virtual_machine_size" {
  description     = "Red5 Pro standalone virtual machine size"
  type            = string
  default         = ""
}
variable "standalone_virtual_machine_storage_type" {
  description     = "Red5 Pro standalone virtual machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type            = string
  default         = "Premium_LRS"
}
variable "standalone_volume_size" {
  description     = "Red5 Pro standalone server volume size"
  type            = number
  default         = 30
  validation {
    condition     = var.standalone_volume_size >= 30
    error_message = "The standalone_volume_size value must be a valid! Minimum 30"
  }
}

variable "red5pro_license_key" {
  description = "Red5 Pro license key (https://www.red5pro.com/docs/installation/installation/license-key/)"
  type        = string
  default     = ""
}
variable "red5pro_api_enable" {
  description = "Red5 Pro Server API enable/disable (https://www.red5pro.com/docs/development/api/overview/)"
  type        = bool
  default     = true
}
variable "red5pro_api_key" {
  description = "Red5 Pro server API key"
  type        = string
  default     = ""
}
variable "standalone_red5pro_inspector_enable" {
  description = "Red5 Pro standalone server Inspector enable/disable (https://www.red5.net/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_restreamer_enable" {
  description = "Red5 Pro standalone server Restreamer enable/disable (https://www.red5.net/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_socialpusher_enable" {
  description = "Red5 Pro standalone server SocialPusher enable/disable (https://www.red5.net/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_suppressor_enable" {
  description = "Red5 Pro standalone server Suppressor enable"
  type        = bool
  default     = false
}
variable "standalone_red5pro_hls_enable" {
  description = "Red5 Pro standalone server HLS enable/disable (https://www.red5.net/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_hls_output_format" {
  description = "Red5 Pro standalone server - HLS output format. Options: TS, FMP4, SMP4"
  type        = string
  default     = "TS"
}
variable "standalone_red5pro_hls_dvr_playlist" {
  description = "Red5 Pro standalone server - HLS DVR playlist"
  type        = string
  default     = "false"
}
variable "standalone_red5pro_webhooks_enable" {
  description = "Red5 Pro standalone server Webhooks enable/disable (https://www.red5.net/docs/special/webhooks/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_webhooks_endpoint" {
  description = "Red5 Pro standalone server Webhooks endpoint"
  type        = string
  default     = ""
}
variable "standalone_red5pro_round_trip_auth_enable" {
  description = "Round trip authentication on the red5pro server enable/disable - Auth server should be deployed separately (https://www.red5.net/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_round_trip_auth_host" {
  description = "Round trip authentication server host"
  type        = string
  default     = ""
}
variable "standalone_red5pro_round_trip_auth_port" {
  description = "Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "standalone_red5pro_round_trip_auth_protocol" {
  description = "Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "standalone_red5pro_round_trip_auth_endpoint_validate" {
  description = "Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "standalone_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}


# Stream Manager Configuration
variable "stream_manager_auth_user" {
  description = "value to set the user name for Stream Manager 2.0 authentication"
  type        = string
  default     = ""
}
variable "stream_manager_auth_password" {
  description = "value to set the user password for Stream Manager 2.0 authentication"
  type        = string
  default     = ""
}
variable "stream_manager_proxy_user" {
  description = "value to set the user name for Stream Manager 2.0 proxy"
  type        = string
  default     = ""
}
variable "stream_manager_proxy_password" {
  description = "value to set the user password for Stream Manager 2.0 proxy"
  type        = string
  default     = ""
}
variable "stream_manager_spatial_user" {
  description = "value to set the user name for Stream Manager 2.0 spatial"
  type        = string
  default     = ""
}
variable "stream_manager_spatial_password" {
  description = "value to set the user password for Stream Manager 2.0 spatial"
  type        = string
  default     = ""
}
variable "stream_manager_version" {
  description = "value to set the version for Stream Manager 2.0"
  type        = string
  default     = "latest"
}
variable "stream_manager_count" {
  description = "SM instance count for autoscale"
  type        = number
  default     = 1
}
variable "stream_manager_machine_size" {
  description = "Stream Manager virtual machine size"
  type        = string
  default     = ""
}
variable "stream_manager_machine_storage_type" {
  description = "Stream Manager storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type        = string
  default     = ""
}
variable "stream_manager_volume_size" {
  description = "value to set the volume size for stream manager"
  type        = number
  default     = 30
  validation {
    condition     = var.stream_manager_volume_size >= 30
    error_message = "The stream_manager_volume_size value must be a valid! Minimum 30"
  }
}

########################################################
# Red5 Pro Netwrok security group configuration
########################################################
# Standalone server Security group
variable "standalone_red5_nsg_tcp_ports" {
  description = "Red5 Pro TCP ports enable for standalone server deloyment"
  type        = list(string)
  default     = ["22", "80", "5080", "443", "1935", "1936", "8554", "8000-8100"]
}

variable "standalone_red5_nsg_udp_ports" {
  description = "Red5 Pro UDP ports enable for standalone server deloyment"
  type        = list(string)
  default     = ["40000-65535", "8000-8100"]
}
# SM server Security Group
variable "stream_manager_red5_nsg_tcp_ports" {
  description = "Red5 Pro TCP ports enable for stream manager server deloyment"
  type        = list(number)
  default     = [22, 80, 9092, 443]
}
# Node server Security group
variable "node_red5_tcp_nsg_ports" {
  description = "Red5 Pro ports enable for nodes"
  type        = list(number)
  default     = [22, 5080, 1935, 8554, 6262, 8081]
}
variable "node_red5_udp_nsg_ports" {
  description = "Red5 Pro ports enable for nodes"
  type        = string
  default     = "40000-65535"
}
########################################################
# Red5 Pro autoscale node image configuration
########################################################
# Red5 Pro Node image configuration
variable "node_image_create" {
  description = "Create new Node image true/false"
  type        = bool
  default     = false
}
variable "node_machine_size" {
  description = "Nnode virtual machine size"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_machine_storage_type" {
  description = "Node machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  default     = ""
  type        = string
}
variable "node_image_volume_size" {
  description = "Node image - volume size"
  type        = number
  default     = 30
  validation {
    condition     = var.node_image_volume_size >= 30
    error_message = "The node_image_volume_size value must be a valid! Minimum 30"
  }
}

# HTTPS/SSL variables for standalone/cluster
variable "https_ssl_certificate" {
  description = "Enable SSL (HTTPS) on the Standalone Red5 Pro server,  Stream Manager 2.0 server or Stream Manager 2.0 Load Balancer"
  type        = string
  default     = "none"
  validation {
    condition     = var.https_ssl_certificate == "none" || var.https_ssl_certificate == "letsencrypt" || var.https_ssl_certificate == "imported"
    error_message = "The https_ssl_certificate value must be a valid! Example: none, letsencrypt, imported"
  }
}
variable "https_ssl_certificate_domain_name" {
  description = "Domain name for SSL certificate (letsencrypt/imported/existing)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_email" {
  description = "Email for SSL certificate (letsencrypt)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_cert_path" {
  description = "Path to public certificate file (imported)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_fullchain_path" {
  description = "Path to certificate chain file (imported)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_key_path" {
  description = "Path to SSL key (imported)"
  type        = string
  default     = ""
}

# Red5 Pro autoscale Node group - (Optional) 
variable "node_group_create" {
  description = "Create new node group. Linux or Mac OS only."
  type        = bool
  default     = false
}
variable "node_group_origins_min" {
  description = "Number of minimum Origins"
  type        = number
  default     = 1
}
variable "node_group_origins_max" {
  description = "Number of maximum Origins"
  type        = number
  default     = 20
}
variable "node_group_origins_machine_size" {
  description = "Machine size for Origins"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_origins_volume_size" {
  description = "Volume size in GB for Origins. Minimum 30GB"
  type        = number
  default     = 30
  validation {
    condition     = var.node_group_origins_volume_size >= 30
    error_message = "The node_group_origins_volume_size value must be a valid! Minimum 30"
  }
}
variable "node_group_edges_min" {
  description = "Number of minimum Edges"
  type        = number
  default     = 1
}
variable "node_group_edges_max" {
  description = "Number of maximum Edges"
  type        = number
  default     = 40
}
variable "node_group_edges_machine_size" {
  description = "Machine size for Edges"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_edges_volume_size" {
  description = "Volume size in GB for Edges. Minimum 30GB"
  type        = number
  default     = 30
  validation {
    condition     = var.node_group_edges_volume_size >= 30
    error_message = "The node_group_edges_volume_size value must be a valid! Minimum 30"
  }
}
variable "node_group_transcoders_min" {
  description = "Number of minimum Transcoders"
  type        = number
  default     = 1
}
variable "node_group_transcoders_max" {
  description = "Number of maximum Transcoders"
  type        = number
  default     = 20
}
variable "node_group_transcoders_machine_size" {
  description = "Machine size for Transcoders"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_transcoders_volume_size" {
  description = "Volume size in GB for Transcoders. Minimum 30GB"
  type        = number
  default     = 30
  validation {
    condition     = var.node_group_transcoders_volume_size >= 30
    error_message = "The node_group_transcoders_volume_size value must be a valid! Minimum 30"
  }
}
variable "node_group_relays_min" {
  description = "Number of minimum Relays"
  type        = number
  default     = 0
}
variable "node_group_relays_max" {
  description = "Number of maximum Relays"
  type        = number
  default     = 20
}
variable "node_group_relays_machine_size" {
  description = "Machine size for Relays"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_relays_volume_size" {
  description = "Volume size in GB for Relays. Minimum 30GB"
  type        = number
  default     = 30
  validation {
    condition     = var.node_group_relays_volume_size >= 30
    error_message = "The node_group_relays_volume_size value must be a valid! Minimum 30"
  }
} 
variable "node_group_origins_connection_limit" {
  description = "Connection limit for Origins (maximum number of publishers to the origin server)"
  type        = number
  default     = 20
}
variable "node_group_edges_connection_limit" {
  description = "Connection limit for Edges (maximum number of subscribers to the edge server)"
  type        = number
  default     = 200
}
variable "node_group_transcoders_connection_limit" {
  description = "Connection limit for Transcoders (maximum number of publishers to the transcoder server)"
  type        = number
  default     = 20
}

# Azure Video On Demand via Cloud Storage configuration
variable "standalone_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "standalone_red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "standalone_red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "standalone_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
# Extra configuration for Red5 Pro autoscaling nodes
variable "node_config_webhooks" {
  description = "Webhooks configuration - (Optional) https://www.red5.net/docs/special/webhooks/overview/"
  type = object({
    enable           = bool
    target_nodes     = list(string)
    webhook_endpoint = string
  })
  default = {
    enable           = false
    target_nodes     = []
    webhook_endpoint = ""
  }
}
variable "node_config_round_trip_auth" {
  description = "Round trip authentication configuration - (Optional) https://www.red5.net/docs/special/authplugin/simple-auth/"
  type = object({
    enable                   = bool
    target_nodes             = list(string)
    auth_host                = string
    auth_port                = number
    auth_protocol            = string
    auth_endpoint_validate   = string
    auth_endpoint_invalidate = string
  })
  default = {
    enable                   = false
    target_nodes             = []
    auth_host                = ""
    auth_port                = "443"
    auth_protocol            = "https://"
    auth_endpoint_validate   = "/validateCredentials"
    auth_endpoint_invalidate = "/invalidateCredentials"
  }
}
variable "node_config_social_pusher" {
  description = "Social Pusher configuration - (Optional) https://www.red5.net/docs/development/social-media-plugin/rest-api/"
  type           = object({
    enable       = bool
    target_nodes = list(string)
  })
  default = {
    enable       = false
    target_nodes = []
  }
}
variable "node_config_restreamer" {
  description = "Restreamer configuration - (Optional) https://www.red5.net/docs/special/restreamer/overview/"
  type                   = object({
    enable               = bool
    target_nodes         = list(string)
    restreamer_tsingest  = bool
    restreamer_ipcam     = bool
    restreamer_whip      = bool
    restreamer_srtingest = bool
  })
  default = {
    enable               = false
    target_nodes         = []
    restreamer_tsingest  = false
    restreamer_ipcam     = false
    restreamer_whip      = false
    restreamer_srtingest = false
  }
}

# kafka configuration
variable "kafka_standalone_instance_create" {
  description = "Create a new Kafka standalone instance true/false"
  type        = bool
  default     = false
}
variable "kafka_service_tcp_nsg_ports" {
  description     = "Red5 Pro ports enable for Kafka service"
  type            = list(number)
  default         = [22, 9092]
}
variable "kafka_service_machine_size" {
  description     = "Kafka service virtual machine size"
  type            = string
  default         = "Standard_F2s_v2"
}
variable "kafka_service_machine_storage_type" {
  description     = "Kafka service virtual machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type            = string
  default         = "Premium_LRS"
}
variable "kafka_standalone_instance_arhive_url" {
  description = "Kafka standalone instance - archive URL"
  type        = string
  default     = "https://downloads.apache.org/kafka/3.9.2/kafka_2.13-3.9.2.tgz"
}
variable "kafka_standalone_volume_size" {
  description = "value to set the volume size for kafka"
  type        = number
  default     = 30
  validation {
    condition     = var.kafka_standalone_volume_size >= 30
    error_message = "The kafka_standalone_volume_size value must be a valid! Minimum 30"
  }
}
variable "stream_manager_container_registry" {
  description = "value to set the container registry for Stream Manager 2.0 (Optional) Example: container-registry/my-repo"
  type        = string
  default     = ""
}
variable "stream_manager_container_registry_user" {
  description = "value to set the user name for Stream Manager 2.0 container registry (Optional)"
  type        = string
  default     = ""
}
variable "stream_manager_container_registry_password" {
  description = "value to set the user password for Stream Manager 2.0 container registry (Optional)"
  type        = string
  default     = ""
}
variable "stream_manager_testbed_version" {
  description = "value to set the version for Stream Manager 2.0 Testbed (Optional) - if not set it will use version from stream_manager_version variable"
  type        = string
  default     = ""
}