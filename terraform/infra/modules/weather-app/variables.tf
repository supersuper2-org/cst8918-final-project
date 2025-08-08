variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
  default     = "Canada Central"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "redis_capacity" {
  description = "Capacity of the Redis cache"
  type        = number
  default     = 0
}

variable "redis_sku" {
  description = "SKU of the Redis cache"
  type        = string
  default     = "Basic"
}

variable "app_replicas" {
  description = "Number of replicas for the weather app"
  type        = number
  default     = 1
}

variable "kubernetes_host" {
  description = "Kubernetes cluster host"
  type        = string
}

variable "kubernetes_client_certificate" {
  description = "Kubernetes client certificate"
  type        = string
  sensitive   = true
}

variable "kubernetes_client_key" {
  description = "Kubernetes client key"
  type        = string
  sensitive   = true
}

variable "kubernetes_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 