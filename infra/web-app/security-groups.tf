resource "aws_security_group" "app" {
  name        = var.ecs_container_security_group_name
  description = "Allow inbound from ALB to ECS container on port ${var.app_port}"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id

  ingress {
    description     = "Allow traffic from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.platform.outputs.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound (ECR pull, Secrets Manager, CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = var.ecs_container_security_group_name }
}
