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

# Define variables to receive the Kubernetes connection details
variable "k8s_host" {
  description = "Kubernetes API server host."
  type        = string
  sensitive   = true
}

variable "k8s_client_certificate" {
  description = "Client certificate for Kubernetes authentication (base64-decoded)."
  type        = string
  sensitive   = true
}

variable "k8s_client_key" {
  description = "Client key for Kubernetes authentication (base64-decoded)."
  type        = string
  sensitive   = true
}

variable "k8s_cluster_ca_certificate" {
  description = "Cluster CA certificate for Kubernetes authentication (base64-decoded)."
  type        = string
  sensitive   = true
}

variable "acr_login_server" {
  description = "Login server for the Azure Container Registry. This is the <acr_name>.azurecr.io"
  type        = string
}

variable "redis_hostname" {
  description = "Hostname of the Redis Cache instance"
  type        = string
}

variable "redis_ssl_port" {
  description = "Port of the Redis Cache instance"
  type        = number
}

variable "redis_primary_key" {
  description = "Primary access key for the Redis Cache instance"
  type        = string
  sensitive   = true
}