# ── ECS Task Execution Role ────────────────────────────────────────────────
# Allows ECS to pull images from ECR, write to CloudWatch, and read from
# Secrets Manager on behalf of the container at startup.

resource "aws_iam_role" "execution" {
  name = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.environment}-ecs-execution-role" }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allows the execution role to read secrets from Secrets Manager
resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.environment}-ecs-execution-secrets-policy"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}-*"
      }
    ]
  })
}

# ── ECS Task Role ──────────────────────────────────────────────────────────
# Attached to the running container. Add service-level AWS API permissions
# here (e.g. S3, SQS) as the application grows.

resource "aws_iam_role" "task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.environment}-ecs-task-role" }
}

# Placeholder inline policy — extend as the application needs AWS API access
resource "aws_iam_role_policy" "task_base" {
  name = "${var.environment}-ecs-task-base-policy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.environment}-*:*"
      }
    ]
  })
}
