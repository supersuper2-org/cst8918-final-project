output "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kubernetes_cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config_raw" {
  description = "Raw kube config"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes cluster host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
}

output "client_certificate" {
  description = "Client certificate"
  value       = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].client_key)
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = base64decode(azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
  sensitive   = true
} 