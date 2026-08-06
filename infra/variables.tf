variable "location" {
  description = "the azure region where the resources will be created"
  type = string
  default = "centralus"
}

variable "project_name" {
  description = "project name"
  type = string
  default = "order-system"
}

variable "environment" {
  description = "application environment"
  type = string
  default = "dev"
}