# ALB Security Group
resource "aws_security_group" "alb" {
  name        = var.alb_security_group_name
  description = "Allow HTTP/HTTPS inbound to the ALB"
  vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = var.alb_security_group_name }
}

# Application Load Balancer (internet-facing)
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.shared.outputs.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = var.alb_name }
}

# HTTP Listener — forwards to services via listener rules.
# For production, replace with an HTTP→HTTPS redirect and add an HTTPS listener
# with an ACM certificate ARN.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

# Access log group for ALB (optional — enable access logs via aws_lb attribute if needed)
resource "aws_cloudwatch_log_group" "alb" {
  name              = "${var.environment}-alb-logs"
  retention_in_days = var.log_retention_days

  tags = { Name = "${var.environment}-alb-logs" }
}
