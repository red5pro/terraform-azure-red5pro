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
  description     = "Type of deployment: single, cluster, autoscaling"
  type            = string
  default         = "single"
  validation {
    condition     = var.type == "single" || var.type == "cluster" || var.type == "autoscaling"
    error_message = "The type value must be a valid! Example: single, cluster, autoscaling"
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
  description     = "Ubuntu version which is going to be used for creating droplet in Digital Ocean"
  type            = string
  default         = "20.04"
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

# Terraform service configuration
variable "terraform_service_instance_create" {
  description     = "Create a dedicated machine for Red5 pro Terraform Service "
  type            = bool
  default         = true
}
variable "terraform_service_tcp_nsg_ports" {
  description     = "Red5 Pro ports enable for Terraform service"
  type            = list(number)
  default         = [22, 8083]
}
variable "terraform_service_machine_size" {
  description     = "Terraform service virtual machine size"
  type            = string
  default         = "Standard_F2s_v2"
}
variable "terraform_service_machine_storage_type" {
  description     = "Terraform service virtual machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type            = string
  default         = "Premium_LRS"
}
variable "terraform_service_api_key" {
  description     = "API key for Teraform Service to autherize the APIs"
  type            = string
  default         = ""
}
variable "terraform_service_parallelism" {
  description     = "Number of Terraform concurrent operations and used for non-standard rate limiting"
  type            = string
  default         = "20"
}
variable "path_to_terraform_cloud_controller" {
  description     = "Path to the Terraform Cloud Controller jar file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/terraform-azure-red5pro/terraform-cloud-controller-0.0.0.jar"
  type            = string
  default         = ""
}

variable "path_to_terraform_service_build" {
  description     = "Path to the Terraform Service build zip file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/terraform-azure-red5pro/terraform-service-0.0.0.zip"
  type            = string
  default         = ""
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
variable "create_azure_resource_group" {
  description     = "Create a new resource group in azure where all the resources will be created"
  type            = bool
  default         = true
}
variable "existing_azure_resource_group_name" {
  description     = "Use the already created resource group of azure account where all the resources will be created"
  type            = string
  default         = ""
}
variable "new_azure_resource_group_name" {
  description     = "Create new resource group of azure account where all the resources will be created"
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
  description     = "Digital Ocean VPC IP range for Red5 Pro"
  type            = string
  default         = "10.0.0.0/16"
}
variable "vpc_create" {
  description     = "Create a new VPC or use an existing one. true = create new, false = use existing"
  type            = bool
  default         = true
}

# Autoscaling Configuration
variable "ssl_certificate_pfx_path" {
  description = "Path to the SSL certificate PFX file."
  type        = string
  default     = ""
}
variable "ssl_certificate_pfx_password" {
  description = "Password for the SSL certificate PFX file."
  type        = string
  default     = "abc123"
}
# Application Gateway variables
variable "application_gateway_sku_name" {
  description = "The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2."
  type        = string
  default     = "Standard_v2"
}
variable "application_gateway_sku_tier" {
  description = "The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2."
  type        = string
  default     = "Standard_v2"
}
variable "application_gateway_sku_capacity" {
  description = "The number of instances to use for this Application Gateway. This value is only allowed to be set when the SKU name is Standard_v2 or WAF_v2."
  type        = number
  default     = 2
}

# Database Configuration
variable "mysql_database_create" {
  description     = "Create a new MySQL Database"
  type            = bool
  default         = false
}
variable "mysql_username" {
  description     = "MySQL user name if mysql_database_create = false"
  type            = string
  default         = ""
}
variable "mysql_database_sku" {
  description     = "MySQL database size"
  type            = string
  default         = "GP_Gen5_2"
}
variable "mysql_storage_mb" {
  description     = "MySQL storage"
  type            = string
  default         = "5120"
}
variable "mysql_port" {
  description     = "MySQL port to be used if mysql_database_create = false "
  type            = number
  default         = 3306
}
variable "mysql_password" {
  description     = "MySQL database password"
  type            = string
  default         = "Abc@123abc45!#&"
  sensitive       = true
  validation {
    condition     = length(var.mysql_password) >= 8
    error_message = "Password must have at least 8 characters."
  }
  validation {
    condition     = can(regex("[A-Z]", var.mysql_password))
    error_message = "Password must contain at least one uppercase letter."
  }
  validation {
    condition     = can(regex("[a-z]", var.mysql_password))
    error_message = "Password must contain at least one lowercase letter."
  }
  validation {
    condition     = can(regex("[^a-zA-Z0-9]", var.mysql_password))
    error_message = "Password must contain at least one character that isn't a letter or a digit."
  }
  validation {
    condition     = can(regex("[0-9]", var.mysql_password))
    error_message = "Password must contain at least one digit."
  }
}

# SSH keys Configuration
variable "create_new_ssh_keys" {
  description     = "Cretae a new SSH key pair which will be used for creating the virtual machines"
  type            = bool
  default         = true
  
}
variable "virtual_machine_size" {
  description     = "Red5 Pro single virtual machine size"
  type            = string
  default         = ""
}
variable "virtual_machine_storage_type" {
  description     = "Red5 Pro single virtual machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  type            = string
  default         = "Premium_LRS"
}
variable "ssh_key_name" {
  description     = "SSH keys name to cretae ssh-key pair"
  type            = string
  default         = ""
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
variable "red5pro_cluster_key" {
  description = "Red5Pro Cluster Key"
  type        = string
  default     = ""
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
variable "red5pro_inspector_enable" {
  description = "Red5 Pro Single server Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_restreamer_enable" {
  description = "Red5 Pro Single server Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_socialpusher_enable" {
  description = "Red5 Pro Single server SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "red5pro_suppressor_enable" {
  description = "Red5 Pro Single server Suppressor enable"
  type        = bool
  default     = false
}
variable "red5pro_hls_enable" {
  description = "Red5 Pro Single server HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_enable" {
  description = "Round trip authentication on the red5pro server enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_host" {
  description = "Round trip authentication server host"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_port" {
  description = "Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "red5pro_round_trip_auth_protocol" {
  description = "Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "red5pro_round_trip_auth_endpoint_validate" {
  description = "Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}


# Stream Manager Configuration
variable "stream_manager_api_key" {
  description = "API Key for Red5Pro Stream Manager"
  type        = string
  default     = ""
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
variable "azure_virtual_machine_password" {
  description = "The virtual machine password used by the stream manager while creating the nodes virtual machine in azure account"
  type        = string
  default     = "Abc@123"
  validation {
    condition     = length(var.azure_virtual_machine_password) >= 6
    error_message = "Password must have at least 6 characters."
  }
  validation {
    condition     = can(regex("[A-Z]", var.azure_virtual_machine_password))
    error_message = "Password must contain at least one uppercase letter."
  }
  validation {
    condition     = can(regex("[a-z]", var.azure_virtual_machine_password))
    error_message = "Password must contain at least one lowercase letter."
  }
  validation {
    condition     = can(regex("[^a-zA-Z0-9]", var.azure_virtual_machine_password))
    error_message = "Password must contain at least one character that isn't a letter or a digit."
  }
  validation {
    condition     = can(regex("[0-9]", var.azure_virtual_machine_password))
    error_message = "Password must contain at least one digit."
  }
}

########################################################
# Red5 Pro Netwrok security group configuration
########################################################
variable "single_red5_nsg_ports" {
  description = "Red5 Pro ports enable for single server deloyment"
  type = list(number)
  default = [22, 80, 5080, 443]
}

variable "stream_manager_red5_nsg_tcp_ports" {
  description = "Red5 Pro TCP ports enable for stream manager server deloyment"
  type = list(number)
  default = [22, 80, 5080, 443]
}

########################################################
# Red5 Pro autoscaling Origin node image configuration
########################################################
# Origin node configuration
variable "node_red5_tcp_nsg_ports" {
  description = "Red5 Pro ports enable for origin node"
  type = list(number)
  default = [22, 5080, 1935, 8554, 6262, 8081]
}
variable "node_red5_udp_nsg_ports" {
  description = "Red5 Pro ports enable for origin node"
  type = string
  default = "40000-65535"
}
variable "origin_image_create" {
  description = "Create new Origin node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "origin_machine_size" {
  description = "Origin node virtual machine size"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "origin_machine_storage_type" {
  description = "Origin machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  default     = ""
  type        = string
}
variable "origin_image_red5pro_inspector_enable" {
  description = "Origin node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_restreamer_enable" {
  description = "Origin node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_socialpusher_enable" {
  description = "Origin node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_suppressor_enable" {
  description = "Origin node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_hls_enable" {
  description = "Origin node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_enable" {
  description = "Origin node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_host" {
  description = "Origin node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_port" {
  description = "Origin node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "origin_image_red5pro_round_trip_auth_protocol" {
  description = "Origin node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Origin node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Origin node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Edge node image configuration
variable "edge_image_create" {
  description = "Create new Edge node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "edge_machine_size" {
  description = "Edge node virtual machine size"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "edge_machine_storage_type" {
  description = "Edge machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  default     = ""
  type        = string
}
variable "edge_image_red5pro_inspector_enable" {
  description = "Edge node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_restreamer_enable" {
  description = "Edge node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_socialpusher_enable" {
  description = "Edge node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_suppressor_enable" {
  description = "Edge node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_hls_enable" {
  description = "Edge node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_enable" {
  description = "Edge node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_host" {
  description = "Edge node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "edge_image_red5pro_round_trip_auth_port" {
  description = "Edge node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "edge_image_red5pro_round_trip_auth_protocol" {
  description = "Edge node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Edge node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Edge node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Transcoder node image configuration
variable "transcoder_image_create" {
  description = "Create new Transcoder node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "transcoder_machine_size" {
  description = "Transcoder node virtual machine size"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "transcoder_machine_storage_type" {
  description = "Transcoder machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  default     = ""
  type        = string
}
variable "transcoder_image_red5pro_inspector_enable" {
  description = "Transcoder node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_restreamer_enable" {
  description = "Transcoder node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_socialpusher_enable" {
  description = "Transcoder node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_suppressor_enable" {
  description = "Transcoder node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_hls_enable" {
  description = "Transcoder node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_enable" {
  description = "Transcoder node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_host" {
  description = "Transcoder node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_round_trip_auth_port" {
  description = "Transcoder node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "transcoder_image_red5pro_round_trip_auth_protocol" {
  description = "Transcoder node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Transcoder node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Transcoder node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Relay node image configuration
variable "relay_image_create" {
  description = "Create new Relay node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "relay_machine_size" {
  description = "Relay node virtual machine size"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "relay_machine_storage_type" {
  description = "Relay machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS"
  default     = ""
  type        = string
}
variable "relay_image_red5pro_inspector_enable" {
  description = "Relay node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_restreamer_enable" {
  description = "Relay node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_socialpusher_enable" {
  description = "Relay node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_suppressor_enable" {
  description = "Relay node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_hls_enable" {
  description = "Relay node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_enable" {
  description = "Relay node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_host" {
  description = "Relay node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "relay_image_red5pro_round_trip_auth_port" {
  description = "Relay node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "relay_image_red5pro_round_trip_auth_protocol" {
  description = "Relay node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Relay node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Relay node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}


# HTTPS/SSL variables for single/cluster
variable "https_letsencrypt_enable" {
  description = "Enable HTTPS and get SSL certificate using Let's Encrypt automaticaly (single/cluster/autoscale) (https://www.red5pro.com/docs/installation/ssl/overview/)"
  type        = bool
  default     = false
}
variable "https_letsencrypt_certificate_domain_name" {
  description = "Domain name for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}
variable "https_letsencrypt_certificate_email" {
  description = "Email for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}
variable "https_letsencrypt_certificate_password" {
  description = "Password for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}

# Red5 Pro autoscaling Node group - (Optional) 
variable "node_group_create" {
  description = "Create new node group. Linux or Mac OS only."
  type        = bool
  default     = false
}
variable "node_group_name" {
  description = "Node group name"
  type        = string
  default     = ""
}
variable "node_group_origins" {
  description = "Number of Origins"
  type        = number
  default     = 1
}
variable "node_group_origins_machine_size" {
  description = "Machine size for Origins"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_origins_capacity" {
  description = "Connections capacity for Origins"
  type        = number
  default     = 30
}
variable "node_group_edges" {
  description = "Number of Edges"
  type        = number
  default     = 1
}
variable "node_group_edges_machine_size" {
  description = "Machine size for Edges"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_edges_capacity" {
  description = "Connections capacity for Edges"
  type        = number
  default     = 300
}
variable "node_group_transcoders" {
  description = "Number of Transcoders"
  type        = number
  default     = 1
}
variable "node_group_transcoders_machine_size" {
  description = "Machine size for Transcoders"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_transcoders_capacity" {
  description = "Connections capacity for Transcoders"
  type        = number
  default     = 30
}
variable "node_group_relays" {
  description = "Number of Relays"
  type        = number
  default     = 1
}
variable "node_group_relays_machine_size" {
  description = "Machine size for Relays"
  type        = string
  default     = "Standard_F2s_v2"
}
variable "node_group_relays_capacity" {
  description = "Connections capacity for Relays"
  type        = number
  default     = 30
}

# Azure Video On Demand via Cloud Storage configuration
variable "red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "origin_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "origin_red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "origin_red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "origin_red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "origin_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "edge_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "edge_red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "edge_red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "edge_red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "edge_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "transcoder_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "transcoder_red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "transcoder_red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "relay_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)"
  type        = bool
  default     = false
}
variable "relay_red5pro_azure_storage_account_name" {
  description = "Red5 Pro server cloud storage - Azure storage account name "
  type        = string
  default     = ""
}
variable "relay_red5pro_azure_storage_account_key" {
  description = "Red5 Pro server cloud storage - Azure storage account key"
  type        = string
  default     = ""
}
variable "relay_red5pro_azure_storage_container_name" {
  description = "Red5 Pro server cloud storage - Azure storage account container name"
  type        = string
  default     = ""
}
variable "relay_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

