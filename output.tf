
################################################################################
# OUTPUTS
################################################################################
output "node_origin_image" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = try(azurerm_image.origin_image[0].name, null)
}

output "node_edge_image" {
  description = "Image name of the Red5 Pro Node Edge image"
  value       = try(azurerm_image.edge_image[0].name, null)
}

output "node_transcoder_image" {
  description = "Image name of the Red5 Pro Node Transcoder image"
  value       = try(azurerm_image.transcoder_image[0].name, null)
}

output "node_relay_image" {
  description = "Image name of the Red5 Pro Node Relay image"
  value       = try(azurerm_image.relay_image[0].name, null)
}

output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = local.ssh_private_key_path
}

output "database_host" {
  description = "MySQL database host"
  value       = local.mysql_host
}

output "database_user" {
  description = "Database User"
  value       = var.mysql_username
}

output "database_port" {
  description = "Database Port"
  value       = var.mysql_port
}

output "database_password" {
  sensitive   = true
  description = "Database Password"
  value       = var.mysql_password
}

output "stream_manager_ip" {
  description = "Stream Manager IP"
  value = local.stream_manager_ip
}

output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster ? "http://${local.stream_manager_ip}:5080" : null
}

output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL"
  value       = local.cluster && var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null
}

output "single_red5pro_single_server_ip" {
  description = "Signle server red5pro ip"
  value       = local.single_server_ip
}

output "single_red5pro_server_http_url" {
  description = "Single Red5 Pro Server HTTP URL"
  value       = local.single ? "http://${local.single_server_ip}:5080" : null
}

output "single_red5pro_server_https_url" {
  description = "Single Red5 Pro Server HTTPS URL"
  value = local.single && var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null
}

output "single_red5pro_server_ip" {
  description = "Single Red5 Pro Server IP"
  value = local.single_server_ip
}




output "load_balancer_url" {
  description = "Load Balancer URL of Red5 Pro server"
  value       = local.autoscaling ? "https://${azurerm_public_ip.lb_ip[0].ip_address}:443" : null
}

output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = local.az_resource_group
}