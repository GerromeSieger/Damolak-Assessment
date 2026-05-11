# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html
resource "aws_ecs_task_definition" "app" {
  family                   = var.ecs_task_definition_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu_units
  memory                   = var.ecs_task_memory_units

  execution_role_arn = data.terraform_remote_state.platform.outputs.execution_role_arn
  task_role_arn      = data.terraform_remote_state.platform.outputs.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.ecs_container_name
      image     = "${data.terraform_remote_state.platform.outputs.ecr_repository_url}:${var.app_image_tag}"
      cpu       = var.ecs_task_cpu_units
      memory    = var.ecs_task_memory_units
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.ecs_container_name
        }
      }

      environment = local.env
      secrets     = local.env_secrets
    }
  ])

  tags = { Name = var.ecs_task_definition_name }
}
