variable "label_prefix" {
  description = "The environment (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group" {
  description = "Resource group name where the virtual network and subnets will be created"
  type        = string
}
