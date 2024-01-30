## Single Red5 Pro server deployment (single)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Security Group** - This Terrform module create a new security group in Microsoft Azure.
* **Machine Size** - Select the appropriate instance size based on the usecase from Microsoft Azure.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
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
| <a name="module_red5pro_single"></a> [red5pro\_single](#module\_red5pro\_single) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_module_output"></a> [module\_output](#output\_module\_output) | n/a |
| <a name="output_red5pro_server_http_url"></a> [red5pro\_server\_http\_url](#output\_red5pro\_server\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_red5pro_server_https_url"></a> [red5pro\_server\_https\_url](#output\_red5pro\_server\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_red5pro_server_ip"></a> [red5pro\_server\_ip](#output\_red5pro\_server\_ip) | Red5 Pro Server IP |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name used for deployment |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
