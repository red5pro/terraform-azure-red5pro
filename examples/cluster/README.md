# Stream Manager 2.0 cluster with autoscaling nodes (cluster)

In the following example, Terraform module will automates the infrastructure provisioning of the Stream Manager 2.0 cluster with Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

## Terraform Deployed Resources (cluster)

- Resource Group (You can use existing resource group)
- Virtual Network
- Public subnet
- Security group for Stream Manager 2.0
- Security group for Kafka
- Security group for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance (optional).
- Stream Manager 2.0 instance. Optionally include a Kafka server on the same instance.
- SSL certificate for Stream Manager 2.0 instance. Options:
  - `none` - Stream Manager 2.0 without HTTPS and SSL certificate. Only HTTP on port `80`
  - `letsencrypt` - Stream Manager 2.0 with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `80`, HTTPS on port `443`
  - `imported` - Stream Manager 2.0 with HTTPS and imported SSL certificate. HTTP on port `80`, HTTPS on port `443`
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

## Example main.tf (cluster)

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=4.57.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = ">=2.8.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = "xxxxxxxxxxxxx"
  client_secret   = "xxxxxxxxxxxxx"
  subscription_id = "xxxxxxxxxxxxx"
  tenant_id       = "xxxxxxxxxxxxx"
}
provider "azapi" {
  client_id       = "xxxxxxxxxxxxx"
  client_secret   = "xxxxxxxxxxxxx"
  subscription_id = "xxxxxxxxxxxxx"
  tenant_id       = "xxxxxxxxxxxxx"
}

module "red5pro_cluster" {
  source                                = "red5pro/red5pro/azure"
  azure_client_id                       = "xxxxxxxxxxxxx"                  # Client id of the Azue account   https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal
  azure_client_secret                   = "xxxxxxxxxxxxx"                  # Client Secret of the Azue account
  azure_subscription_id                 = "xxxxxxxxxxxxx"                  # Subscription id of the Azue account
  azure_tenant_id                       = "xxxxxxxxxxxxx"                  # Tenant id of the Azue account
  azure_region                          = "eastus"                         # Azure region where resources will create eg: eastus

  azure_resource_group_use_existing        = false                         # false - create a new resource group, true -use existing resource group
  existing_azure_resource_group_name       = "example-group-name"          # If azure_resource_group_use_existing = true, provide existing resource group name where new resources will be created

  ubuntu_version                        = "22.04"                          # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                                  = "cluster"                        # Deployment type: standalone, cluster, autoscale
  name                                  = "red5pro-cluster"                # Name to be used on all the resources as identifier
  path_to_red5pro_build                 = "./red5pro-server-0.0.0.0-release.zip"   # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_use_existing                  = false                            # true - Use existing SSH key, false - create new SSH keys
  existing_public_ssh_key_path          = "./example-public.pub"           # Path to existing SSH public key
  existing_private_ssh_key_path         = "./example-private.pem"          # Path to existing SSH private key

  # VPC configuration
  vpc_cidr_block                        = "10.5.0.0/16"                    # VPC CIDR value for creating a new vpc in Azure

  # Kafka Service configuration
  kafka_standalone_instance_create      = false
  kafka_standalone_volume_size          = "30"                             # Volume size in GB for Kafka standalone instance
  kafka_service_machine_size            = "Standard_F8s_v2"                # Machine size for Kafka service
  kafka_service_machine_storage_type    = "Premium_LRS"                    # Kafka service storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS

  # Red5 Pro general configuration
  red5pro_license_key                   = "1111-2222-3333-4444"            # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable                    = true                             # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                       = "example_key"                    # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Stream Manager Instance configuration
  stream_manager_machine_size           = "Standard_F4s_v2"                # Machine size for stream manager
  stream_manager_machine_storage_type   = "Premium_LRS"                    # Stream Manager storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  stream_manager_volume_size            = 30                               # Volume size for Stream Manager
  stream_manager_auth_user              = "example_user"                   # Stream Manager 2.0 authentication user name
  stream_manager_auth_password          = "example_password"               # Stream Manager 2.0 authentication password
  stream_manager_proxy_user             = "example_proxy_user"             # Stream Manager 2.0 proxy user name
  stream_manager_proxy_password         = "example_proxy_password"         # Stream Manager 2.0 proxy password
  stream_manager_spatial_user           = "example_spatial_user"           # Stream Manager 2.0 spatial user name
  stream_manager_spatial_password       = "example_spatial_password"       # Stream Manager 2.0 spatial password
  stream_manager_version                = "latest"                         # Stream Manager 2.0 docker images version (latest, 14.1.0, 14.1.1, etc.) - https://hub.docker.com/r/red5pro/as-admin/tags

  # Stream Manager 2.0 server HTTPS (SSL) certificate configuration
  https_ssl_certificate                 = "none"                           # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate               = "letsencrypt"
  # https_ssl_certificate_domain_name   = "red5pro.example.com"            # Replace with your domain name
  # https_ssl_certificate_email         = "email@example.com"              # Replace with your email

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate               = "imported"
  # https_ssl_certificate_domain_name   = "red5pro.example.com"             # Replace with your domain name
  # https_ssl_certificate_cert_path     = "/PATH/TO/SSL/CERT/fullchain.pem" # Path to cert file or full chain file
  # https_ssl_certificate_key_path      = "/PATH/TO/SSL/KEY/privkey.pem"    # Path to privkey file

  # Red5 Pro autoscaling Node image configuration
  node_image_create                     = true                             # Default: true for Autoscaling and Cluster, true - create new Node image, false - not create new Node image
  node_machine_size                     = "Standard_F2s_v2"                # Machine size for Origin node image
  node_machine_storage_type             = "Premium_LRS"                    # Origin machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  node_image_volume_size                = 30                               # Origin node volume size
  
  # Extra configuration for Red5 Pro autoscaling nodes
  # Webhooks configuration - (Optional) https://www.red5.net/docs/special/webhooks/overview/
  node_config_webhooks = {
    enable           = false,
    target_nodes     = ["origin", "edge", "transcoder"],
    webhook_endpoint = "https://test.webhook.app/api/v1/broadcast/webhook"
  }
  # Round trip authentication configuration - (Optional) https://www.red5.net/docs/special/authplugin/simple-auth/
  node_config_round_trip_auth = {
    enable                   = false,
    target_nodes             = ["origin", "edge", "transcoder"],
    auth_host                = "round-trip-auth.example.com",
    auth_port                = 443,
    auth_protocol            = "https://",
    auth_endpoint_validate   = "/validateCredentials",
    auth_endpoint_invalidate = "/invalidateCredentials"
  }
  # Restreamer configuration - (Optional) https://www.red5.net/docs/special/restreamer/overview/
  node_config_restreamer = {
    enable               = false,
    target_nodes         = ["origin", "transcoder"],
    restreamer_tsingest  = true,
    restreamer_ipcam     = true,
    restreamer_whip      = true,
    restreamer_srtingest = true
  }
  # Social Pusher configuration - (Optional) https://www.red5.net/docs/development/social-media-plugin/rest-api/
  node_config_social_pusher = {
    enable       = false,
    target_nodes = ["origin", "edge", "transcoder"],
  }
 
  # Red5 Pro autoscaling Node group
  node_group_create                       = true              # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_origins_min                  = 1                 # Number of minimum Origins
  node_group_origins_max                  = 20                # Number of maximum Origins
  node_group_origins_machine_size         = "Standard_F2s_v2" # Machine size for Origins
  node_group_origins_volume_size          = 30                # Volume size for Origins
  node_group_origins_connection_limit     = 20                # Maximum number of publishers to the origin server
  node_group_edges_min                    = 1                 # Number of minimum Edges
  node_group_edges_max                    = 20                # Number of maximum Edges
  node_group_edges_machine_size           = "Standard_F2s_v2" # Machine size for Edges
  node_group_edges_volume_size            = 30                # Volume size for Edges
  node_group_edges_connection_limit       = 200               # Maximum number of subscribers to the edge server
  node_group_transcoders_min              = 0                 # Number of minimum Transcoders
  node_group_transcoders_max              = 20                # Number of maximum Transcoders
  node_group_transcoders_machine_size     = "Standard_F2s_v2" # Machine size for Transcoders
  node_group_transcoders_volume_size      = 30                # Volume size for Transcoders
  node_group_transcoders_connection_limit = 20                # Maximum number of publishers to the transcoder server
  node_group_relays_min                   = 0                 # Number of minimum Relays
  node_group_relays_max                   = 20                # Number of maximum Relays
  node_group_relays_machine_size          = "Standard_F2s_v2" # Machine size for Relays
  node_group_relays_volume_size           = 30                # Volume size for Relays
}

output "module_output" {
  value = module.red5pro_cluster
}
```
