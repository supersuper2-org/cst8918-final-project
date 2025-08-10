variable "environment" {
  description = "The environment for the AKS cluster, e.g., 'development', 'staging', 'production'."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the AKS cluster will be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the AKS cluster will be created."
  type        = string
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the AKS cluster."
  type        = bool
}

variable "minimum_node_count" {
  description = "The minimum number of nodes in the AKS cluster."
  type        = number
}

variable "maximum_node_count" {
  description = "The maximum number of nodes in the AKS cluster."
  type        = number
}

variable "subnet_id" {
  description = "The ID of the subnet where the AKS cluster will be deployed."
  type        = string
}

variable "service_cidr" {
  description = "The CIDR for the Kubernetes service network."
  type        = string
}

variable "dns_service_ip" {
  description = "The IP address for the Kubernetes DNS service."
  type        = string
}

variable "acr_id" {
  description = "The ID of the Azure Container Registry to which the AKS cluster will have access."
  type        = string
}

