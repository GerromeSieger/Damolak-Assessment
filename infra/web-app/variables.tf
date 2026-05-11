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

#------------------------------------------------------------------------------#
# ALB
#------------------------------------------------------------------------------#
variable "alb_target_group_name" {
  type = string
}

variable "alb_listener_rule_priority" {
  type = number
}

variable "alb_health_check_path" {
  type    = string
  default = "/api/health"
}

#------------------------------------------------------------------------------#
# ECS
#------------------------------------------------------------------------------#
variable "ecs_task_definition_name" {
  type = string
}

variable "ecs_container_name" {
  type = string
}

variable "ecs_container_security_group_name" {
  type = string
}

variable "ecs_task_cpu_units" {
  type    = number
  default = 512
}

variable "ecs_task_memory_units" {
  type    = number
  default = 1024
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_service_desired_task_count" {
  type = number
}

variable "health_check_grace_period" {
  type    = number
  default = 60
}

#------------------------------------------------------------------------------#
# CloudWatch
#------------------------------------------------------------------------------#
variable "cloudwatch_log_group_name" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 30
}

#------------------------------------------------------------------------------#
# Application
#------------------------------------------------------------------------------#
variable "app_port" {
  type    = number
  default = 3000
}

variable "app_image_tag" {
  type        = string
  description = "Image tag deployed by CI/CD (e.g. web-app-latest-dev)"
}

variable "app_env" {
  type        = map(string)
  description = "Non-sensitive environment variables"
  default     = {}
}

variable "app_secret_name" {
  type = string
}

#------------------------------------------------------------------------------#
# Auto Scaling
#------------------------------------------------------------------------------#
variable "enable_auto_scaling" {
  type    = bool
  default = false
}

variable "auto_scaling_min_capacity" {
  type    = number
  default = 1
}

variable "auto_scaling_max_capacity" {
  type    = number
  default = 5
}

variable "auto_scaling_target_cpu" {
  type    = number
  default = 70
}

variable "auto_scaling_target_memory" {
  type    = number
  default = 80
}

variable "auto_scaling_scale_in_cooldown" {
  type    = number
  default = 300
}

variable "auto_scaling_scale_out_cooldown" {
  type    = number
  default = 300
}
