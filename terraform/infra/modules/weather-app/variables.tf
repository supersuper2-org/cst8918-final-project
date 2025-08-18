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

variable "openweather_api_key" {
  description = "API key for OpenWeatherMap service"
  type        = string
  sensitive   = true
}

variable "acr_username" {
  type        = string
  description = "Azure Container Registry username"
  validation {
    condition     = length(var.acr_username) > 0
    error_message = "ACR username must not be empty. Ensure TF_VAR_acr_username is set in your CI/CD pipeline."
  }
}

variable "acr_password" {
  type        = string
  description = "Azure Container Registry password"
  sensitive   = true
  validation {
    condition     = length(var.acr_password) > 0
    error_message = "ACR password must not be empty. Ensure TF_VAR_acr_password is set in your CI/CD pipeline."
  }
}

variable "app_image_tag" {
  description = "Tag for the application image in Azure Container Registry"
  type        = string
  default     = "latest"
}