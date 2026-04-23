# Terraform Module for Deploying Red5 Pro on Microsoft Azure (Azure) - Stream Manager 2.0
[Red5 Pro](https://www.red5.net/) is a real-time video streaming server plaform known for its low-latency streaming capabilities, making it ideal for interactive applications like online gaming, streaming events and video conferencing etc.

This is a reusable Terraform module that provisions infrastructure on [Microsoft Azure(Azure)](https://portal.azure.com/).

## Preparation

### Install Terraform

- Visit the [Terraform download page](https://developer.hashicorp.com/terraform/downloads) and ensure you get version 1.7.5 or higher.
- Download the suitable version for your operating system.
- Extract the compressed file and copy the Terraform binary to a location within your system's PATH.
- Configure PATH for **Linux/macOS**:
  - Open a terminal and type the following command:

    ```sh
    sudo mv /path/to/terraform /usr/local/bin
    ```

- Configure PATH for **Windows**:
  - Click 'Start', search for 'Control Panel', and open it.
  - Navigate to `System > Advanced System Settings > Environment Variables`.
  - Under System variables, find 'PATH' and click 'Edit'.
  - Click 'New' and paste the directory location where you extracted the terraform.exe file.
  - Confirm changes by clicking 'OK' and close all open windows.
  - Open a new terminal and verify that Terraform has been successfully installed.

  ```sh
  terraform --version
  ```

### Install jq

- Install **jq** (Linux or Mac OS only) [Download](https://jqlang.github.io/jq/download/)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`
  > It is used in bash scripts to create/delete Stream Manager node group using API

### Install bc

- Install **bc** (Linux or Mac OS only) [Download](https://www.gnu.org/software/bc/)
  - Linux: `apt install bc`
  - MacOS: `brew install bc`
  > It is used in bash scripts to create/delete Stream Manager node group using API

### Red5 Pro artifacts

- Download Red5 Pro server build in your [Red5 Pro Account](https://account.red5.net/downloads). Example: `red5pro-server-0.0.0.b0-release.zip`
- Get Red5 Pro License key in your [Red5 Pro Account](https://account.red5.net/downloads). Example: `1111-2222-3333-4444`


### Prepare Azure account

- Create a Service Principal for the Terraform module. The Service Principal must have permission to create and manage the following resources:
  - Azure Active Directory (App Registration / Service Principal)
  - Resource Groups
  - Virtual Networks and Subnets
  - Virtual Machines and Scale Sets
  - Load Balancers
  - Public IP Addresses
  - Network Security Groups
  - Managed Disks
- Create a Service Principal with Contributor role assigned at the Subscription
  - You can follow this terraform docs for setup process [Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal)

- Obtain the necessary credentials and information that will be used in terraform:
  - Subscription ID
  - Tenant ID
  - Client ID
  - Client Secret

## This module supports three variants of Red5 Pro deployments

- **standalone** - Standalone Red5 Pro server
- **cluster** - Stream Manager 2.0 cluster with autoscaling nodes
- **autoscale** - Autoscaling Stream Managers 2.0 with autoscaling nodes

### Standalone Red5 Pro server (standalone) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/standalone)

In the following example, Terraform module will automates the infrastructure provisioning of the [Red5 Pro standalone server](https://www.red5.net/docs/installation/).

**`stream_manager_public_hostname`** is only for **cluster** and **autoscale** deployments. Standalone uses **`https_ssl_certificate_domain_name`** when TLS is enabled.

#### Terraform Deployed Resources (standalone)

- Resource Group (You can use existing resource group)
- Virtual Network
- Public subnet
- Security group for Standalone Red5 Pro server
- SSH key pair (use existing or create a new one)
- Standalone Red5 Pro server instance
- SSL certificate for Standalone Red5 Pro server instance. Options:
  - `none` - Red5 Pro server without HTTPS and SSL certificate. Only HTTP on port `5080`
  - `letsencrypt` - Red5 Pro server with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `5080`, HTTPS on port `443`
  - `imported` - Red5 Pro server with HTTPS and imported SSL certificate. HTTP on port `5080`, HTTPS on port `443`

#### Example main.tf (standalone)

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

module "red5pro_standalone" {
  source                                   = "red5pro/red5pro/azure"
  azure_region                             = "eastus"                                # Azure region where resources will create eg: eastus

  azure_resource_group_use_existing        = false                                   # false - create a new resource group, true -use existing resource group
  existing_azure_resource_group_name       = "example-group-name"                    # If azure_resource_group_use_existing = true, provide existing resource group name where new resources will be created

  ubuntu_version                           = "22.04"                                 # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                                     = "standalone"                            # Deployment type: standalone, cluster, autoscale
  name                                     = "red5pro-standalone"                    # Name to be used on all the resources as identifier
  path_to_red5pro_build                    = "./red5pro-server-0.0.0.0-release.zip"  # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_use_existing                     = false                                   # true - Use existing SSH key, false - create new SSH keys
  existing_public_ssh_key_path             = "./example-public.pub"                  # Path to existing SSH public key
  existing_private_ssh_key_path            = "./example-private.pem"                 # Path to existing SSH private key

  # VPC configuration
  vpc_cidr_block                           = "10.5.0.0/16"                           # VPC CIDR value for creating a new vpc in Azure

  # standalone Red5 Pro server Instance configuration
  standalone_virtual_machine_size          = "Standard_F2s_v2"                       # Machine size for Red5 Pro server
  standalone_virtual_machine_storage_type  = "Premium_LRS"                           # Storage type for Red5 Pro server (Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS)

  # Red5Pro general configuration
  red5pro_license_key                      = "1111-2222-3333-4444"                   # Red5 Pro license key (https://account.red5.net/login)
  red5pro_api_enable                       = true                                    # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5.net/docs/development/api/overview/)
  red5pro_api_key                          = "example_key"                           # Red5 Pro server API key (https://www.red5.net/docs/development/api/overview/)

  # Standalone Red5 Pro server HTTPS (SSL) certificate configuration
  https_ssl_certificate                    = "none"                                  # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate                  = "letsencrypt"
  # https_ssl_certificate_domain_name      = "red5pro.example.com"                   # FQDN on the certificate and in browser HTTPS URLs for this server
  # https_ssl_certificate_email            = "email@example.com"                     # Replace with your email

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate                  = "imported"
  # https_ssl_certificate_domain_name      = "red5pro.example.com"                   # FQDN on the certificate and in browser HTTPS URLs for this server
  # https_ssl_certificate_cert_path        = "/PATH/TO/SSL/CERT/fullchain.pem"       # Path to cert file or full chain file
  # https_ssl_certificate_key_path         = "/PATH/TO/SSL/KEY/privkey.pem"          # Path to privkey file
  
  # Standalone Red5pro Server Configuration
  standalone_red5pro_inspector_enable                    = false                             # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5.net/docs/troubleshooting/inspector/overview/)
  standalone_red5pro_restreamer_enable                   = false                             # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5.net/docs/special/restreamer/overview/)
  standalone_red5pro_socialpusher_enable                 = false                             # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5.net/docs/special/social-media-plugin/overview/)
  standalone_red5pro_suppressor_enable                   = false                             # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  standalone_red5pro_hls_enable                          = false                             # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5.net/docs/protocols/hls-plugin/hls-vod/)
  standalone_red5pro_hls_output_format                   = "TS"                              # HLS output format. Options: TS, FMP4, SMP4
  standalone_red5pro_hls_dvr_playlist                    = "false"                           # HLS DVR playlist. Options: true, false
  standalone_red5pro_webhooks_enable                     = false                             # true - enable Red5 Pro server webhooks, false - disable Red5 Pro server webhooks (https://www.red5.net/docs/special/webhooks/overview/)
  standalone_red5pro_webhooks_endpoint                   = "https://example.com/red5/status" # Red5 Pro server webhooks endpoint
  standalone_red5pro_round_trip_auth_enable              = false                             # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5.net/docs/special/round-trip-auth/overview/)
  standalone_red5pro_round_trip_auth_host                = "round-trip-auth.example.com"     # Round trip authentication server host
  standalone_red5pro_round_trip_auth_port                = 3000                              # Round trip authentication server port
  standalone_red5pro_round_trip_auth_protocol            = "http"                            # Round trip authentication server protocol
  standalone_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"            # Round trip authentication server endpoint for validate
  standalone_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"          # Round trip authentication server endpoint for invalidate
  standalone_red5pro_cloudstorage_enable                 = false                             # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)
  standalone_red5pro_azure_storage_account_name          = ""                                # Red5 Pro server cloud storage - Azure storage account name
  standalone_red5pro_azure_storage_account_key           = ""                                # Red5 Pro server cloud storage - Azure storage account key
  standalone_red5pro_azure_storage_container_name        = ""                                # Red5 Pro server cloud storage - Azure storage container name
  standalone_red5pro_cloudstorage_postprocessor_enable   = false                             # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/) 
}

output "module_output" {
  value = module.red5pro_standalone
}
```

### Stream Manager 2.0 cluster with autoscaling nodes (cluster) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/cluster)

In the following example, Terraform module will automates the infrastructure provisioning of the Stream Manager 2.0 cluster with Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

Set **`stream_manager_public_hostname`** to the DNS name clients use for Stream Manager (e.g. `sm.example.com`). It configures Traefik, the admin UI API base URL, and outputs such as `stream_manager_url_https`. Use a real FQDN, not a wildcard. **`https_ssl_certificate_domain_name`** is separate: it identifies the TLS certificate (and may be a wildcard like `*.example.com` or an ACM primary name) as long as the cert covers `stream_manager_public_hostname`.

#### Terraform Deployed Resources (cluster)

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

#### Example main.tf (cluster)

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
  stream_manager_public_hostname        = "sm.example.com"                 # Required: public FQDN for Traefik, admin UI, and HTTPS URLs (not a wildcard). Point DNS A record at the Stream Manager IP from outputs.

  # Stream Manager 2.0 server HTTPS (SSL) certificate configuration
  https_ssl_certificate                 = "none"                           # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate               = "letsencrypt"
  # https_ssl_certificate_domain_name   = "sm.example.com"                 # Cert domain name (may be *.example.com); must cover stream_manager_public_hostname
  # https_ssl_certificate_email         = "email@example.com"              # Replace with your email

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate               = "imported"
  # https_ssl_certificate_domain_name   = "red5pro.example.com"             # Cert domain name (may be *.example.com); must cover stream_manager_public_hostname
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

### Autoscaling Stream Managers 2.0 with autoscaling nodes (autoscale) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/autoscale)

In the following example, Terraform module will automates the infrastructure provisioning of the Autoscale Stream Managers 2.0 with Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

Set **`stream_manager_public_hostname`** to the DNS name clients use (e.g. `sm.example.com`); point DNS at the load balancer hostname from outputs. It configures Traefik, the admin UI, and `stream_manager_url_https`. Use a concrete FQDN, not a wildcard. **`https_ssl_certificate_domain_name`** selects the ACM / TLS identity and may be a wildcard if it covers this hostname.

#### Terraform Deployed Resources (autoscale)

- Resource Group (You can use existing resource group)
- Virtual Network
- Public subnet
- Security group for Stream Manager 2.0
- Security group for Kafka
- Security group for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance
- Stream Manager 2.0 instance image
- Instance poll for Stream Manager 2.0 instances
- Autoscaling configuration for Stream Manager 2.0 instances
- Application Load Balancer for Stream Manager 2.0 instances.
- SSL certificate for Application Load Balancer. Options:
  - `none` - Load Balancer without HTTPS and SSL certificate. Only HTTP on port `80`
  - `imported` - Load Balancer with HTTPS and imported SSL certificate. HTTP on port `80`, HTTPS on port `443`
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)


#### Example main.tf (autoscale)

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

module "red5pro_autoscale" {
  source                              = "red5pro/red5pro/azure"
  azure_client_id                     = "xxxxxxxxxxxxx"                   # Client id of the Azue account
  azure_client_secret                 = "xxxxxxxxxxxxx"                   # Client Secret id of the Azue account
  azure_subscription_id               = "xxxxxxxxxxxxx"                   # Subscription id of the Azue account
  azure_tenant_id                     = "xxxxxxxxxxxxx"                   # Tenant id of the Azue account
  azure_region                        = "eastus"                          # Azure region where resources will create eg: eastus

  azure_resource_group_use_existing        = false                        # false - create a new resource group, true -use existing resource group
  existing_azure_resource_group_name       = "example-group-name"         # If azure_resource_group_use_existing = true, provide existing resource group name where new resources will be created

  ubuntu_version                      = "22.04"                           # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                                = "autoscale"                       # Deployment type: standalone, cluster, autoscale
  name                                = "red5pro-autoscale"               # Name to be used on all the resources as identifier
  path_to_red5pro_build               = "./red5pro-server-0.0.0.0-release.zip" # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_use_existing                = false                             # true - Use existing SSH key, false - create new SSH keys
  existing_public_ssh_key_path        = "./example-public.pub"            # Path to existing SSH public key
  existing_private_ssh_key_path       = "./example-private.pem"           # Path to existing SSH private key

  # VPC configuration
  vpc_cidr_block                      = "10.5.0.0/16"                     # VPC CIDR value for creating a new vpc in Azure

  # Kafka Service configuration
  kafka_standalone_volume_size        = "30"                              # Volume size in GB for Kafka standalone instance
  kafka_service_machine_size          = "Standard_F8s_v2"                 # Machine size for Kafka service
  kafka_service_machine_storage_type  = "Premium_LRS"                     # Kafka service storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS

  # Red5 Pro general configuration
  red5pro_license_key                 = "1111-2222-3333-4444"             # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable                  = true                              # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                     = "example_key"                     # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Stream Manager Instance configuration
  stream_manager_count                = 2                                 # Stream Manager 2.0 instance count
  stream_manager_machine_size         = "Standard_F4s_v2"                 # Machine size for stream manager
  stream_manager_machine_storage_type = "Premium_LRS"                     # Stream Manager storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  stream_manager_volume_size          = 30                                # Volume size for Stream Manager
  stream_manager_auth_user            = "example_user"                    # Stream Manager 2.0 authentication user name
  stream_manager_auth_password        = "example_password"                # Stream Manager 2.0 authentication password
  stream_manager_proxy_user           = "example_proxy_user"              # Stream Manager 2.0 proxy user name
  stream_manager_proxy_password       = "example_proxy_password"          # Stream Manager 2.0 proxy password
  stream_manager_spatial_user         = "example_spatial_user"            # Stream Manager 2.0 spatial user name
  stream_manager_spatial_password     = "example_spatial_password"        # Stream Manager 2.0 spatial password
  stream_manager_version              = "latest"                          # Stream Manager 2.0 docker images version (latest, 14.1.0, 14.1.1, etc.) - https://hub.docker.com/r/red5pro/as-admin/tags
  stream_manager_public_hostname      = "sm.example.com"                  # Required: public FQDN for Traefik, admin UI, and HTTPS URLs (not a wildcard). Point DNS A/alias at the load balancer DNS name from outputs.

  # Stream Manager 2.0 server HTTPS (SSL) certificate configuration
  https_ssl_certificate               = "none"                            # none - do not use HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate             = "imported"
  # https_ssl_certificate_domain_name = "red5pro.example.com"             # Cert domain name (may be *.example.com); must cover stream_manager_public_hostname
  # https_ssl_certificate_cert_path   = "/PATH/TO/SSL/CERT/fullchain.pem" # Path to cert file or full chain file
  # https_ssl_certificate_key_path    = "/PATH/TO/SSL/KEY/privkey.pem"    # Path to privkey file

  # Red5 Pro autoscaling Node image configuration
  node_image_create                   = true                              # Default: true for Autoscaling and Cluster, true - create new Node image, false - not create new Node image
  node_machine_size                   = "Standard_F2s_v2"                 # Machine size for Origin node image
  node_machine_storage_type           = "Premium_LRS"                     # Origin machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  node_image_volume_size              = 30                                # Origin node volume size
  
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
  node_group_create                       = true             # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_origins_min                  = 1                # Number of minimum Origins
  node_group_origins_max                  = 20               # Number of maximum Origins
  node_group_origins_machine_size        = "Standard_F2s_v2" # Machine size for Origins
  node_group_origins_volume_size          = 30               # Volume size for Origins
  node_group_origins_connection_limit     = 20               # Maximum number of publishers to the origin server
  node_group_edges_min                    = 1                # Number of minimum Edges
  node_group_edges_max                    = 20               # Number of maximum Edges
  node_group_edges_machine_size          = "Standard_F2s_v2" # Machine size for Edges
  node_group_edges_volume_size            = 30               # Volume size for Edges
  node_group_edges_connection_limit       = 200              # Maximum number of subscribers to the edge server
  node_group_transcoders_min              = 0                # Number of minimum Transcoders
  node_group_transcoders_max              = 20               # Number of maximum Transcoders
  node_group_transcoders_machine_size    = "Standard_F2s_v2" # Machine size for Transcoders
  node_group_transcoders_volume_size      = 30               # Volume size for Transcoders
  node_group_transcoders_connection_limit = 20               # Maximum number of publishers to the transcoder server
  node_group_relays_min                   = 0                # Number of minimum Relays
  node_group_relays_max                   = 20               # Number of maximum Relays
  node_group_relays_machine_size         = "Standard_F2s_v2" # Machine size for Relays
  node_group_relays_volume_size           = 30               # Volume size for Relays
}

output "module_output" {
  value = module.red5pro_autoscale
}
```

> - WebRTC broadcast does not work in WEB browsers without an HTTPS (SSL) certificate.
> - To activate HTTPS/SSL, you need to add a DNS A record for the public IP address of your Red5 Pro server or Stream Manager 2.0.
