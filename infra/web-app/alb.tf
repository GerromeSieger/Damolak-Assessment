# ALB Target Group
resource "aws_lb_target_group" "app" {
  name                 = var.alb_target_group_name
  port                 = var.app_port
  vpc_id               = data.terraform_remote_state.shared.outputs.vpc_id
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 5

  health_check {
    enabled             = true
    interval            = 10
    unhealthy_threshold = 2
    healthy_threshold   = 2
    protocol            = "HTTP"
    path                = var.alb_health_check_path
    port                = var.app_port
  }

  tags = { Name = var.alb_target_group_name }
}

# ALB HTTP Listener Rule — forwards matching traffic to this service
resource "aws_lb_listener_rule" "http" {
  listener_arn = data.terraform_remote_state.platform.outputs.alb_http_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = { Name = "${var.ecs_service_name}-alb-rule" }
}
