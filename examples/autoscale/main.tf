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
  azure_region              = "eastus"                                                       # Azure region where resources will create eg: eastus

  create_azure_resource_group        = true                                                  # True - Create a new resource group in azure account, False - Use existing resource group
  existing_azure_resource_group_name = ""                                                    # If create_azure_resource_group = false, the existing resource group name should follow this namning convention 'resource_group_name-region'.
  new_azure_resource_group_name      = "example-group-name"                                  # If create_azure_resource_group = true, Provide new resource group name, the region name will automatically add in the end of resource group name. eg: new_azure_resource_group_name='new_resource', Region='eastus'. Final name of resource group='new_resource-eastus'

  ubuntu_version            = "22.04"                                                        # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                      = "autoscaling"                                                  # Deployment type: single, cluster, autoscaling
  name                      = "red5pro-autoscaling"                                          # Name to be used on all the resources as identifier
  path_to_red5pro_build     = "./red5pro-server-0.0.0.0-release.zip"                         # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_terraform_cloud_controller = "./terraform-cloud-controller-0.0.0.jar"              # Absolute path or relative path to terraform cloud controller jar file
  path_to_terraform_service_build    = "./terraform-service-0.0.0.zip"                       # Absolute path or relative path to terraform service ZIP file

  # SSH key configuration
  create_new_ssh_keys              = true                                                    # true - create new SSH key, false - use existing SSH key
  ssh_key_name                     = "new_key_name"                                          # Name for new SSH key
  existing_public_ssh_key_path     = "./example-public.pub"                                  # Path to existing SSH public key
  existing_private_ssh_key_path    = "./example-private.pem"                                 # Path to existing SSH private key
  
  # VPC configuration
  vpc_cidr_block                   = "10.5.0.0/16"                                           # VPC CIDR value for creating a new vpc in Azure

  # Database Configuration
  mysql_database_sku        = "GP_Standard_D2ds_v4"                                          # New database sku name. The name of the SKU, follows the tier + family + cores pattern (e.g. GP_Standard_D2ds_v4, GP_Standard_D2ds_v5).
  mysql_storage_mb          = "5120"                                                         # Specifies the maximum storage allowed for a given server. eg: 5120
  mysql_username            = "example_user"                                                 # Username for locally install databse and dedicated database in azure
  mysql_password            = "Abc@123abc456ABC"                                             # Password for locally install databse and dedicated database in azure
  mysql_port                = 3306                                                           # Port for locally install databse and dedicated database in azure

  # Red5 Pro general configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key                           = ""                                         # Red5 Pro cluster key
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = ""                                         # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Terraform Service configuration
  terraform_service_api_key         = "examplekey"                                           # Terraform service api key
  terraform_service_parallelism     = "20"                                                   # Terraform service parallelism
  terraform_service_machine_size    = "Standard_F2s_v2"                                      # Instance size for Terraform service
  terraform_service_machine_storage_type    = "Premium_LRS"                                  # Terraform service storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS

  # Application Gateway Configuration
  application_gateway_sku_name               = "Standard_v2"                                 # The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
  application_gateway_sku_tier               = "Standard_v2"                                 # The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2.
  application_gateway_sku_capacity           = 2                                             # The number of instances to use for this Application Gateway. This value is only allowed to be set when the SKU name is Standard_v2 or WAF_v2.          

  # Red5 Pro server Instance configuration
  stream_manager_machine_size                   = "Standard_F2s_v2"                          # Instance size for Red5 Pro server
  stream_manager_machine_storage_type           = "Premium_LRS"                              # Stream Manager storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  stream_manager_api_key                        = ""                                         # Stream Manager api key
  azure_virtual_machine_password                = "Abc@1234"                                 # Virtual machine password which is to be used for created nodes of red5 pro.
  
  # Load Balancer Configuraion
  ssl_certificate_pfx_path                      = ""                                       # Path of the PFX format SSL certificate used for the Load Balancer
  ssl_certificate_pfx_password                  = ""                                       # Certificate password used while converting to PFX

  # Red5 Pro autoscale Origin node image configuration
  origin_image_create                                      = true                          # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_machine_size                                      = "Standard_F2s_v2"             # Instance type for Origin node image
  origin_machine_storage_type                              = "Premium_LRS"                 # Origin machine storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS  
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
  origin_red5pro_cloudstorage_enable                   = false                             # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)
  origin_red5pro_azure_storage_account_name            = ""                                # Red5 Pro server cloud storage - Azure storage account name
  origin_red5pro_azure_storage_account_key             = ""                                # Red5 Pro server cloud storage - Azure storage account key
  origin_red5pro_azure_storage_container_name          = ""                                # Red5 Pro server cloud storage - Azure storage container name
  origin_red5pro_cloudstorage_postprocessor_enable     = false                             # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/) 

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                   = true                                               # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name                     = "example-node-group"                               # Node group name
  # Origin node configuration
  node_group_origins_min               = 1                                                 # Number of minimum Origins
  node_group_origins_max               = 20                                                # Number of maximum Origins
  node_group_origins_machine_size     = "Standard_F2s_v2"                                  # Origins azure instance
  node_group_origins_capacity         = 30                                                 # Connections capacity for Origins
  # Edge node configuration
  node_group_edges_min                 = 1                                                 # Number of minimum Edges
  node_group_edges_max                 = 40                                                # Number of maximum Edges
  node_group_edges_machine_size       = "Standard_F2s_v2"                                  # Edges azure instance
  node_group_edges_capacity           = 300                                                # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders_min           = 0                                                 # Number of minimum Transcoders
  node_group_transcoders_max           = 20                                                # Number of maximum Transcoders
  node_group_transcoders_machine_size = "Standard_F2s_v2"                                  # Transcodersazure instance
  node_group_transcoders_capacity     = 30                                                 # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays_min                = 0                                                 # Number of minimum Relays
  node_group_relays_max                = 20                                                # Number of maximum Relays
  node_group_relays_machine_size      = "Standard_F2s_v2"                                  # Relays azure instance
  node_group_relays_capacity          = 30                                                 # Connections capacity for Relays

}

output "module_output" {
  sensitive = true
  value = module.red5pro_autoscaling
}