variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Must be one of: dev, prod."
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "ecr_repository_name" {
  type    = string
  default = "web-app-ecr"
}

variable "ecr_image_retention_count" {
  type    = number
  default = 10
}

variable "ecs_cluster_name" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "alb_security_group_name" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}
