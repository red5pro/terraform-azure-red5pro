# Microsoft Azure Red5 Pro Terraform module
[Red5 Pro](https://www.red5.net/) is a real-time video streaming server plaform known for its low-latency streaming capabilities, making it ideal for interactive applications like online gaming, streaming events and video conferencing etc.

This a reusable Terraform installer module for [Red5 Pro](https://www.red5.net/docs/installation/installation/azurequickstart/) that provisions infrastucture over [Microsoft Azure(Azure)](https://portal.azure.com/).

## This module has 3 variants of Red5 Pro deployments

* **single** - Single instance with installed and configured Red5 Pro server
* **cluster** - Stream Manager cluster (MySQL DB + Stream Manager instance + Terraform Service + Autoscaling Node group with Origin, Edge, Transcoder, Relay droplets)
* **autoscaling** - Autoscaling Stream Managers (MySQL DB + Load Balancer + Autoscaling Stream Managers + Terraform Service + Autoscaling Node group with Origin, Edge, Transcoder, Relay droplets)

---

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/downloads
  * Open your web browser and visit the [Terraform download page](https://developer.hashicorp.com/terraform/downloads), ensuring you get version 1.0.0 or higher. 
  * Download the suitable version for your operating system, 
  * Extract the compressed file, and then copy the Terraform binary to a location within your system's path
    * Configure path on Linux/macOS 
      * Open a terminal and type the following:

        ```$ sudo mv /path/to/terraform /usr/local/bin```
    * Configure path on Windows OS
      * Click 'Start', search for 'Control Panel', and open it.
      * Navigate to System > Advanced System Settings > Environment Variables.
      * Under System variables, find 'PATH' and click 'Edit'.
      * Click 'New' and paste the directory location where you extracted the terraform.exe file.
      * Confirm changes by clicking 'OK' and close all open windows.
      * Open a new terminal and verify that Terraform has been successfully installed.

* Install **Microsoft Azure CLI** https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-0.0.0.b0-release.zip) https://account.red5pro.com/downloads
* Download Red5 Pro Terraform controller : (Example: terraform-cloud-controller-0.0.0.jar) https://account.red5pro.com/downloads
* Download Red5 Pro Terraform Service : (Example: terraform-service-0.0.0.zip) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Login to microsoft azure cli (To login to CLI follow the below documents) 
  * Follow the documentation for generating API keys - https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli
* Copy Red5 Pro server build, Terraform controller and Terraform service to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/terraform-cloud-controller-0.0.0.jar ./
cp ~/Downloads/terraform-service-0.0.0.zip ./
```

## Single Red5 Pro server deployment (single) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/single)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Security Group** - This Terrform module create a new security group in Microsoft Azure.
* **SSH KEYS** - This module can create and use already created SSH Keys
* **Machine Size** - Select the appropriate instance size based on the usecase from Microsoft Azure.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).

## Usage (single)

```hcl
module "red5pro_single" {
  source                    = "../../"
  azure_region              = "eastus"                                                       # Azure region where resources will create eg: eastus

  create_azure_resource_group        = true                                                  # True - Create a new resource group in azure account, False - Use existing resource group
  existing_azure_resource_group_name = ""                                                    # If create_azure_resource_group = false, the existing resource group name should follow this namning convention 'resource_group_name-region'.
  new_azure_resource_group_name      = "test-group-name"                                     # If create_azure_resource_group = true, Provide new resource group name, the region name will automatically add in the end of resource group name. eg: new_azure_resource_group_name='new_resource', Region='eastus'. Final name of resource group='new_resource-eastus'

  ubuntu_version            = "22.04"                                                        # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                      = "single"                                                       # Deployment type: single, cluster, autoscaling
  name                      = "red5pro-single"                                               # Name to be used on all the resources as identifier
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
  virtual_machine_size                          = "Standard_F2s_v2"                          # Instance size for Red5 Pro server
  virtual_machine_storage_type                  = "Premium_LRS"                              # Storage type for Red5 Pro server (Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS)

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
```

---

## Red5 Pro Stream Manager cluster deployment (cluster) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/cluster)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Security Group** - This Terrform module create a new security group in Microsoft Azure.
* **Instance Size** - Select the appropriate instance size based on the usecase from Microsoft Azure.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).
* **MySQL Database** - Users have flexibility to create a MySQL databse server in Microsoft Azure or install it locally on the Stream Manager
* **SSH KEYS** - This module can create and use already created SSH Keys
* **Terraform Service** - Users has the flexibity to either create dedicate Terraform service instance or loacally install on the Stream Manager
* **Stream Manager** - Instance will be created automatically for Stream Manager
* **Origin Node Image** - To create Microsoft Azure(Azure) custom image for Orgin Node type for Stream Manager node group
* **Edge Node Image** - To create Microsoft Azure(Azure) custom image for Edge Node type for Stream Manager node group (optional)
* **Transcoder Node Image** - To create Microsoft Azure(Azure) custom image for Transcoder Node type for Stream Manager node group (optional)
* **Relay Node Image** - To create Microsoft Azure(Azure) custom image for Relay Node type for Stream Manager node group (optional)

## Usage (cluster)

```hcl
module "red5pro_cluster" {
  source                    = "../../"
  azure_client_id           = ""                                                             # Client id of the Azue account
  azure_client_secret       = ""                                                             # Client Secret id of the Azue account
  azure_subscription_id     = ""                                                             # Subscription id of the Azue account
  azure_tenant_id           = ""                                                             # Tenant id of the Azue account
  azure_region              = "eastus"                                                       # Azure region where resources will create eg: eastus

  create_azure_resource_group        = true                                                  # True - Create a new resource group in azure account, False - Use existing resource group
  existing_azure_resource_group_name = ""                                                    # If create_azure_resource_group = false, the existing resource group name should follow this namning convention 'resource_group_name-region'.
  new_azure_resource_group_name      = "test-group-name"                                     # If create_azure_resource_group = true, Provide new resource group name, the region name will automatically add in the end of resource group name. eg: new_azure_resource_group_name='new_resource', Region='eastus'. Final name of resource group='new_resource-eastus'

  ubuntu_version            = "22.04"                                                        # The version of ubuntu which is used to create Instance, it can either be 20.04 or 22.04
  type                      = "cluster"                                                      # Deployment type: single, cluster, autoscaling
  name                      = "red5pro-cluster"                                                             # Name to be used on all the resources as identifier
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
  mysql_database_create     = true                                                           # true - create a new database false- Install locally
  mysql_database_sku        = "GP_Gen5_2"                                                    # New database sku name. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen5_1, GP_Gen5_8).
  mysql_storage_mb          = "5120"                                                         # Specifies the maximum storage allowed for a given server. eg: 5120
  mysql_username            = "example-user"                                                 # Username for locally install databse and dedicated database in azure
  mysql_password            = "Abc@123abc45!@2"                                              # Password for locally install databse and dedicated database in azure
  mysql_port                = 3306                                                           # Port for locally install databse and dedicated database in azure

  # Terraform Service configuration
  terraform_service_instance_create = false                                                  # true - Create a dedicate terraform service machine, false - install terraform service locally on the stream manager
  terraform_service_api_key         = ""                                                     # Terraform service api key
  terraform_service_parallelism     = "20"                                                   # Terraform service parallelism
  terraform_service_machine_size    = "Standard_F2s_v2"                                      # Instance size for Terraform service
  terraform_service_machine_storage_type    = "Premium_LRS"                                  # Terraform service storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS

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
  
  # Red5 Pro server Instance configuration
  stream_manager_machine_size                   = "Standard_F2s_v2"                          # Instance size for Red5 Pro server
  stream_manager_machine_storage_type           = "Premium_LRS"                              # Stream Manager storage type. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS
  stream_manager_api_key                        = ""                                         # Stream Manager api key
  azure_virtual_machine_password                = "Abc@1234"                                 # Virtual machine password which is to be used for created nodes of red5 pro.

  # Red5 Pro cluster Origin node image configuration
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
  node_group_origins                  = 1                                                  # Number of Origins
  node_group_origins_machine_size     = "Standard_F2s_v2"                                  # Origins azure instance
  node_group_origins_capacity         = 30                                                 # Connections capacity for Origins
  # Edge node configuration
  node_group_edges                    = 1                                                  # Number of Edges
  node_group_edges_machine_size       = "Standard_F2s_v2"                                  # Edges azure instance
  node_group_edges_capacity           = 300                                                # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders              = 1                                                  # Number of Transcoders
  node_group_transcoders_machine_size = "Standard_F2s_v2"                                  # Transcodersazure instance
  node_group_transcoders_capacity     = 30                                                 # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays                   = 1                                                  # Number of Relays
  node_group_relays_machine_size      = "Standard_F2s_v2"                                  # Relays azure instance
  node_group_relays_capacity          = 30                                                 # Connections capacity for Relays

}

output "module_output" {
  sensitive = true
  value = module.red5pro_cluster
}
```
## Red5 Pro Stream Manager autoscaling deployment (autoscaling) - [Example](https://github.com/red5pro/terraform-azure-red5pro/tree/master/examples/autoscale)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Security Group** - This Terrform module create a new security group in Microsoft Azure.
* **Instance Size** - Select the appropriate instance size based on the usecase from Microsoft Azure.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).
* **MySQL Database** - Users have flexibility to create a MySQL databse server in Microsoft Azure or install it locally on the Stream Manager
* **SSH KEYS** - This module can create and use already created SSH Keys
* **Terraform Service** - This module create dedicate Terraform service instance for the Stream Manager
* **Stream Manager** - Instance will be created automatically for Stream Manager
* **Application Gateway** - This Terraform Module create the application gateway to distribute the requests.
* **Origin Node Image** - To create Microsoft Azure(Azure) custom image for Orgin Node type for Stream Manager node group
* **Edge Node Image** - To create Microsoft Azure(Azure) custom image for Edge Node type for Stream Manager node group (optional)
* **Transcoder Node Image** - To create Microsoft Azure(Azure) custom image for Transcoder Node type for Stream Manager node group (optional)
* **Relay Node Image** - To create Microsoft Azure(Azure) custom image for Relay Node type for Stream Manager node group (optional)

## Usage (autoscaling)

```hcl
module "red5pro_autoscaling" {
  source                    = "../../"
  azure_client_id           = ""                                                             # Client id of the Azue account
  azure_client_secret       = ""                                                             # Client Secret id of the Azue account
  azure_subscription_id     = ""                                                             # Subscription id of the Azue account
  azure_tenant_id           = ""                                                             # Tenant id of the Azue account
  azure_region              = "eastus"                                                       # Azure region where resources will create eg: eastus

  create_azure_resource_group        = true                                                  # True - Create a new resource group in azure account, False - Use existing resource group
  existing_azure_resource_group_name = ""                                                    # If create_azure_resource_group = false, the existing resource group name should follow this namning convention 'resource_group_name-region'.
  new_azure_resource_group_name      = "test-group-name"                                     # If create_azure_resource_group = true, Provide new resource group name, the region name will automatically add in the end of resource group name. eg: new_azure_resource_group_name='new_resource', Region='eastus'. Final name of resource group='new_resource-eastus'

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
  mysql_database_sku        = "GP_Gen5_2"                                                    # New database sku name. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen5_1, GP_Gen5_8).
  mysql_storage_mb          = "5120"                                                         # Specifies the maximum storage allowed for a given server. eg: 5120
  mysql_username            = "example-user"                                                 # Username for locally install databse and dedicated database in azure
  mysql_password            = "@E1example-password"                                          # Password for locally install databse and dedicated database in azure
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
  node_group_origins                  = 1                                                  # Number of Origins
  node_group_origins_machine_size     = "Standard_F2s_v2"                                  # Origins azure instance
  node_group_origins_capacity         = 30                                                 # Connections capacity for Origins
  # Edge node configuration
  node_group_edges                    = 1                                                  # Number of Edges
  node_group_edges_machine_size       = "Standard_F2s_v2"                                  # Edges azure instance
  node_group_edges_capacity           = 300                                                # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders              = 1                                                  # Number of Transcoders
  node_group_transcoders_machine_size = "Standard_F2s_v2"                                  # Transcodersazure instance
  node_group_transcoders_capacity     = 30                                                 # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays                   = 1                                                  # Number of Relays
  node_group_relays_machine_size      = "Standard_F2s_v2"                                  # Relays azure instance
  node_group_relays_capacity          = 30                                                 # Connections capacity for Relays

}

output "module_output" {
  sensitive = true
  value = module.red5pro_autoscaling
}

```

---

**NOTES**

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP (single/cluster) or CNAME record for Load Balancer DNS name (autoscaling)

---

