resource "aws_ecs_service" "app" {
  name                              = var.ecs_service_name
  cluster                           = data.terraform_remote_state.platform.outputs.ecs_cluster_id
  task_definition                   = aws_ecs_task_definition.app.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.ecs_service_desired_task_count
  health_check_grace_period_seconds = var.health_check_grace_period

  network_configuration {
    subnets          = data.terraform_remote_state.shared.outputs.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.ecs_container_name
    container_port   = var.app_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = { Name = var.ecs_service_name }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.auto_scaling_max_capacity
  min_capacity       = var.auto_scaling_min_capacity
  resource_id        = "service/${data.terraform_remote_state.platform.outputs.ecs_cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = { Name = "${var.ecs_service_name}-asg-target" }
}

# Auto Scaling Policy — CPU
resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.ecs_service_name}-cpu-asg"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.auto_scaling_target_cpu
    scale_in_cooldown  = var.auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.auto_scaling_scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

# Auto Scaling Policy — Memory
resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${var.ecs_service_name}-memory-asg"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.auto_scaling_target_memory
    scale_in_cooldown  = var.auto_scaling_scale_in_cooldown
    scale_out_cooldown = var.auto_scaling_scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}
