output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "secrets_manager_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "app_url" {
  description = "ALB DNS name — point your domain here"
  value       = "http://${data.terraform_remote_state.platform.outputs.alb_dns_name}"
}
