#################################################
# Example for single Red5 Pro server deployment #
#################################################

module "red5pro_single" {
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
  type                      = "single"                                                       # Deployment type: single, cluster, autoscaling
  name                      = ""                                                             # Name to be used on all the resources as identifier
  path_to_red5pro_build     = "./red5pro-server-0.0.0-release.zip"                           # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  create_new_ssh_keys              = true                                                    # true - create new SSH key, false - use existing SSH key
  ssh_key_name                     = "new_key_name"                                          # Name for new SSH key
  existing_public_ssh_key_path     = "./example-public.pub"                                  # Path to existing SSH public key
  existing_private_ssh_key_path    = "./example-private.pem"                                 # Path to existing SSH private key

  # VPC configuration
  vpc_cidr_block                   = "10.5.0.0/16"                                           # VPC CIDR value for creating a new vpc in Azure

  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server Instance configuration
  virtual_machine_size                          = "Standard_F2"                              # Instance size for Red5 Pro server

  # Red5Pro server configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = "examplekey"                               # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_inspector_enable                      = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)
  red5pro_restreamer_enable                     = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/)
  red5pro_socialpusher_enable                   = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/)
  red5pro_suppressor_enable                     = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  red5pro_hls_enable                            = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/)
  red5pro_round_trip_auth_enable                = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  red5pro_round_trip_auth_host                  = "round-trip-auth.example.com"              # Round trip authentication server host
  red5pro_round_trip_auth_port                  = 3000                                       # Round trip authentication server port
  red5pro_round_trip_auth_protocol              = "http"                                     # Round trip authentication server protocol
  red5pro_round_trip_auth_endpoint_validate     = "/validateCredentials"                     # Round trip authentication server endpoint for validate
  red5pro_round_trip_auth_endpoint_invalidate   = "/invalidateCredentials"                   # Round trip authentication server endpoint for invalidate
  red5pro_cloudstorage_enable                   = false                                      # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/azure-cloudstorage/)
  red5pro_azure_storage_account_name            = ""                                         # Red5 Pro server cloud storage - Azure storage account name
  red5pro_azure_storage_account_key             = ""                                         # Red5 Pro server cloud storage - Azure storage account key
  red5pro_azure_storage_container_name          = ""                                         # Red5 Pro server cloud storage - Azure storage container name
  red5pro_cloudstorage_postprocessor_enable     = false                                      # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/) 

}

output "module_output" {
  sensitive = true
  value = module.red5pro_single
}