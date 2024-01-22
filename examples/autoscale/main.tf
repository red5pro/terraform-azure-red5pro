#################################################
# Example for autoscale Red5 Pro server deployment
#################################################
provider "azurerm" {
  features {}
  client_id           = ""                                                             # Client id of the Azue account
  client_secret       = ""                                                             # Client Secret id of the Azue account
  subscription_id     = ""                                                             # Subscription id of the Azue account
  tenant_id           = ""                                                             # Tenant id of the Azue account
  skip_provider_registration = true
}

module "red5pro_autoscaling" {
  source                    = "../../"
  azure_client_id           = ""                                                             # Client id of the Azue account
  azure_client_secret       = ""                                                             # Client Secret id of the Azue account
  azure_subscription_id     = ""                                                             # Subscription id of the Azue account
  azure_tenant_id           = ""                                                             # Tenant id of the Azue account
  azure_region              = "centralindia"                                                 # Azure region where resources will create eg: centralindia

  create_azure_resource_group        = true                                                  # True - Create a new resource group in azure account, False - Use existing resource group
  existing_azure_resource_group_name = ""                                                    # If create_azure_resource_group = false, Provide the existing resouce group name
  new_azure_resource_group_name      = "TestGroup"                                           # If create_azure_resource_group = true, new resource group name to be used

  ubuntu_version            = "20.04"                                                        # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                      = "autoscaling"                                                  # Deployment type: single, cluster, autoscaling
  name                      = ""                                                             # Name to be used on all the resources as identifier
  path_to_red5pro_build     = "./red5pro-server-0.0.0-release.zip"                           # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_azure_cloud_controller = "./azure-cloud-controller--0.0.0.jar"                     # Absolute path or relative path to azure cloud controller jar file

  # SSH key configuration
  create_new_ssh_keys              = true                                                    # true - create new SSH key, false - use existing SSH key
  ssh_key_name                     = "new_key_name"                                          # Name for new SSH key
  existing_public_ssh_key_path     = "./example-public.pub"                                  # Path to existing SSH public key
  existing_private_ssh_key_path    = "./example-private.pem"                                 # Path to existing SSH private key
  
  # VPC configuration
  vpc_cidr_block                   = "10.5.0.0/16"                                           # VPC CIDR value for creating a new vpc in Azure

  # Database Configuration
  mysql_database_sku        = "GP_Gen5_2"                                                     # New database sku name. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen5_1, GP_Gen5_8).
  mysql_storage_mb          = "5120"                                                         # Specifies the maximum storage allowed for a given server. eg: 5120
  mysql_username            = "example-user"                                                 # Username for locally install databse and dedicated database in azure
  mysql_password            = "@E1example-password"                                          # Password for locally install databse and dedicated database in azure
  mysql_port                = 3306                                                           # Port for locally install databse and dedicated database in azure

  # Red5 Pro general configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key                           = ""                                         # Red5 Pro cluster key
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = ""                                         # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate

  # Application Gateway Configuration
  application_gateway_sku_name               = "Standard_v2"                                 # The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
  application_gateway_sku_tier               = "Standard_v2"                                 # The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2.

  # Red5 Pro server Instance configuration
  stream_manager_machine_size                   = "Standard_F2"                              # Instance size for Red5 Pro server
  stream_manager_api_key                        = ""                                         # Stream Manager api key
  azure_virtual_machine_password                = "Abc@1234"                                 # Virtual machine password which is to be used for created nodes of red5 pro.

  # Red5 Pro cluster Origin node image configuration
  origin_image_create                                      = true                          # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_machine_size                                      = "Standard_F2"                 # Instance type for Origin node image
  origin_image_red5pro_inspector_enable                    = false                         # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)
  origin_image_red5pro_restreamer_enable                   = false                         # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/)
  origin_image_red5pro_socialpusher_enable                 = false                         # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/)
  origin_image_red5pro_suppressor_enable                   = false                         # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                          = false                         # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/)
  origin_image_red5pro_round_trip_auth_enable              = false                         # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  origin_image_red5pro_round_trip_auth_host                = "round-trip-auth.example.com" # Round trip authentication server host
  origin_image_red5pro_round_trip_auth_port                = 3000                          # Round trip authentication server port
  origin_image_red5pro_round_trip_auth_protocol            = "http"                        # Round trip authentication server protocol
  origin_image_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"        # Round trip authentication server endpoint for validate
  origin_image_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"      # Round trip authentication server endpoint for invalidate
  origin_red5pro_cloudstorage_enable                   = false                                      # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)
  origin_red5pro_azure_storage_account_name            = ""                                         # Red5 Pro server cloud storage - Azure storage account name
  origin_red5pro_azure_storage_account_key             = ""                                         # Red5 Pro server cloud storage - Azure storage account key
  origin_red5pro_azure_storage_container_name          = ""                                         # Red5 Pro server cloud storage - Azure storage container name
  origin_red5pro_cloudstorage_postprocessor_enable     = false                                      # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/) 

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create = true                                                                 # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name   = "example-node-group"                                                 # Node group name
  # Origin node configuration
  node_group_origins               = 1                                                     # Number of Origins
  node_group_origins_machine_size = "Standard_F2"                                          # Origins azure instance
  node_group_origins_capacity      = 30                                                    # Connections capacity for Origins
  # Edge node configuration
  node_group_edges               = 1                                                       # Number of Edges
  node_group_edges_machine_size = "Standard_F2"                                            # Edges azure instance
  node_group_edges_capacity      = 300                                                     # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders               = 1                                                 # Number of Transcoders
  node_group_transcoders_machine_size = "Standard_F2"                                      # Transcodersazure instance
  node_group_transcoders_capacity      = 30                                                # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays               = 1                                                      # Number of Relays
  node_group_relays_machine_size = "Standard_F2"                                           # Relays azure instance
  node_group_relays_capacity      = 30                                                     # Connections capacity for Relays

}

output "module_output" {
  sensitive = true
  value = module.red5pro_autoscaling
}