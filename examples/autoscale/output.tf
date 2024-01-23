output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro_autoscaling.ssh_private_key_path
}

output "stream_manager_ip" {
  description = "Red5 Pro Server IP"
  value       = module.red5pro_autoscaling.stream_manager_ip
}

output "red5pro_server_http_url" {
  description = "Red5 Pro Server HTTP URL"
  value       = module.red5pro_autoscaling.stream_manager_http_url
}

output "red5pro_server_https_url" {
  description = "Red5 Pro Server HTTPS URL"
  value       = module.red5pro_autoscaling.stream_manager_https_url
}

output "database_host" {
  description = "MySQL database host"
  value       = module.red5pro_autoscaling.database_host
}

output "database_user" {
  description = "Database User"
  value       = module.red5pro_autoscaling.database_user
}

output "database_port" {
  description = "Database Port"
  value       = module.red5pro_autoscaling.database_port
}

output "database_password" {
  sensitive   = true
  description = "Database Password"
  value       = module.red5pro_autoscaling.database_password
}

output "node_origin_image" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = module.red5pro_autoscaling.node_origin_image
}

output "node_edge_image" {
  description = "Image name of the Red5 Pro Node Edge image"
  value       = module.red5pro_autoscaling.node_edge_image
}

output "node_transcoder_image" {
  description = "Image name of the Red5 Pro Node Transcoder image"
  value       = module.red5pro_autoscaling.node_transcoder_image
}

output "node_relay_image" {
  description = "Image name of the Red5 Pro Node Relay image"
  value       = module.red5pro_autoscaling.node_relay_image
}

output "load_balancer_url" {
  description = "Load Balancer URL for Red5 Pro server"
  value       = module.red5pro_autoscaling.load_balancer_url
}

output "resource_group_name" {
  description = "Resource group name used for deployment"
  value       = module.red5pro_autoscaling.resource_group_name
}