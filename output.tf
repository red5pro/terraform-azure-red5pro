
# ################################################################################
# # OUTPUTS
# ################################################################################
output "vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}
output "node_image_name" {
  description = "Node image name"
  value       = local.node_image_name
}
output "security_group_name_node" {
  description = "Node security group name"
  value       = local.security_group_name_node
}
output "security_group_name_kafka" {
  description = "Kafka security group name"
  value       = local.security_group_name_kafka
}
output "security_group_name_sm" {
  description = "Stream Manager security group name"
  value       = local.security_group_name_sm
}
output "stream_manager_ip" {
  description = "Stream Manager 2.0 Public IP or Load Balancer Public IP"
  value       = local.cluster_or_autoscale ? local.stream_manager_ip : null
}
output "stream_manager_url_http" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster_or_autoscale ? "http://${local.stream_manager_ip}:80" : null
}
output "stream_manager_url_https" {
  description = "Stream Manager HTTPS URL (hostname from stream_manager_public_hostname, not https_ssl_certificate_domain_name — supports wildcard certs)"
  value       = local.cluster_or_autoscale && var.https_ssl_certificate != "none" && var.stream_manager_public_hostname != "" ? "https://${var.stream_manager_public_hostname}:443" : null
}
output "ssh_key_name" {
  description = "SSH key name"
  value       = try(azurerm_ssh_public_key.red5pro_ssh[0].name, null)
}
output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = local.ssh_private_key_path
}
output "ssh_username" {
  description = "SSH username to connect with virtual machine"
  value       = "ubuntu" 
}
output "azure_region" {
  description = "Azure region where resources has been created"
  value       = var.azure_region
}
output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = local.az_resource_group_name
}
output "manual_dns_record" {
  description = "DNS hint for TLS: cluster/autoscale uses stream_manager_public_hostname; standalone uses https_ssl_certificate_domain_name"
  value = var.https_ssl_certificate != "none" ? (
    local.cluster_or_autoscale ? "Please create DNS A record for Stream Manager 2.0: '${var.stream_manager_public_hostname}' -> '${local.stream_manager_ip}'"
    : "Please create DNS A record for Standalone Red5 Pro: '${var.https_ssl_certificate_domain_name}' -> '${local.standalone_server_ip}'"
  ) : ""
}
output "standalone_red5pro_server_ip" {
  description = "Standalone Red5 Pro Server IP"
  value       = local.standalone ? local.standalone_server_ip : null
}
output "standalone_red5pro_server_http_url" {
  description = "Standalone Red5 Pro Server HTTP URL"
  value       = local.standalone ? "http://${local.standalone_server_ip}:5080" : null
}
output "standalone_red5pro_server_https_url" {
  description = "Standalone Red5 Pro Server HTTPS URL"
  value       = local.standalone && var.https_ssl_certificate != "none" ? "https://${var.https_ssl_certificate_domain_name}:443" : null
}
output "standalone_red5pro_server_security_group_name" {
  description = "Security group name Standalone Red5 Pro server"
  value       = try(azurerm_network_security_group.red5_network_standalone_security_group[0].name, null)
}
