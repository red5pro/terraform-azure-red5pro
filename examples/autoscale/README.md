## Red5 Pro Stream Manager autoscaling deployment (autoscaling)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Security Group** - This Terrform module create a new security group in Microsoft Azure.
* **Instance Size** - Select the appropriate instance size based on the usecase from Microsoft Azure.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).
* **MySQL Database** - Users have flexibility to create a MySQL databse server in Microsoft Azure or install it locally on the Stream Manager
* **Stream Manager** - instance will be created automatically for Stream Manager
* **Application Gateway** - This Terraform Module create the application gateway to distribute the requests.
* **Origin Node Image** - To create Microsoft Azure(Azure) custom image for Orgin Node type for Stream Manager node group
* **Edge Node Image** - To create Microsoft Azure(Azure) custom image for Edge Node type for Stream Manager node group (optional)
* **Transcoder Node Image** - To create Microsoft Azure(Azure) custom image for Transcoder Node type for Stream Manager node group (optional)
* **Relay Node Image** - To create Microsoft Azure(Azure) custom image for Relay Node type for Stream Manager node group (optional)

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/terraform-cloud-controller-0.0.0.jar ./
cp ~/Downloads/terraform-service-0.0.0.zip ./
```

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Notes

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP of Red5 Pro server
* Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.

## Azure regions

```
australiacentral,australiacentral2,australiaeast,australiasoutheast,brazilsouth,brazilsoutheast,brazilus,canadacentral,canadaeast,centralindia,centralus,centraluseuap,eastasia,eastus,eastus2,eastus2euap,francecentral,francesouth,germanynorth,germanywestcentral,israelcentral,italynorth,japaneast,japanwest,jioindiacentral,jioindiawest,koreacentral,koreasouth,malaysiasouth,mexicocentral,northcentralus,northeurope,norwayeast,norwaywest,polandcentral,qatarcentral,southafricanorth,southafricawest,southcentralus,southeastasia,southindia,spaincentral,swedencentral,swedensouth,switzerlandnorth,switzerlandwest,uaecentral,uaenorth,uksouth,ukwest,westcentralus,westeurope,westindia,westus,westus2,westus3,austriaeast,centralusfoundational,chilecentral,eastusslv,israelnorthwest,malaysiawest,newzealandnorth,westeuropefoundational
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.80.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.80.0 |
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_red5pro_autoscaling"></a> [red5pro\_autoscaling](#module\_red5pro\_autoscaling) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_host"></a> [database\_host](#output\_database\_host) | MySQL database host |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | Database Password |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | Database Port |
| <a name="output_database_user"></a> [database\_user](#output\_database\_user) | Database User |
| <a name="output_load_balancer_url"></a> [load\_balancer\_url](#output\_load\_balancer\_url) | Load Balancer URL for Red5 Pro server |
| <a name="output_module_output"></a> [module\_output](#output\_module\_output) | n/a |
| <a name="output_node_edge_image"></a> [node\_edge\_image](#output\_node\_edge\_image) | Image name of the Red5 Pro Node Edge image |
| <a name="output_node_origin_image"></a> [node\_origin\_image](#output\_node\_origin\_image) | Image name of the Red5 Pro Node Origin image |
| <a name="output_node_relay_image"></a> [node\_relay\_image](#output\_node\_relay\_image) | Image name of the Red5 Pro Node Relay image |
| <a name="output_node_transcoder_image"></a> [node\_transcoder\_image](#output\_node\_transcoder\_image) | Image name of the Red5 Pro Node Transcoder image |
| <a name="output_red5pro_server_http_url"></a> [red5pro\_server\_http\_url](#output\_red5pro\_server\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_red5pro_server_https_url"></a> [red5pro\_server\_https\_url](#output\_red5pro\_server\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name used for deployment |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_stream_manager_ip"></a> [stream\_manager\_ip](#output\_stream\_manager\_ip) | Red5 Pro Server IP |
| <a name="output_terraform_service_ip"></a> [terraform\_service\_ip](#output\_terraform\_service\_ip) | Terraform service IP address |