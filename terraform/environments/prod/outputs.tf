output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.network.resource_group_name
}

output "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.aks.kubernetes_cluster_name
}