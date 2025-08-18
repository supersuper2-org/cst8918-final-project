variable "weather_api_key" {
  description = "API key for OpenWeatherMap service"
  type        = string
  sensitive   = true
}

variable "acr_username" {
  description = "Username for Azure Container Registry authentication."
  type        = string
}

variable "acr_password" {
  description = "Password for Azure Container Registry authentication."
  type        = string
  sensitive   = true
}

variable "app_image_tag" {
  description = "The tag for the application image in the Azure Container Registry."
  type        = string
}