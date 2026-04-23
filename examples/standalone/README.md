# Standalone Red5 Pro server (standalone)

In the following example, Terraform module will automates the infrastructure provisioning of the [Red5 Pro standalone server](https://www.red5.net/docs/installation/).

## Terraform Deployed Resources (standalone)

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

## Example main.tf (standalone)

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
