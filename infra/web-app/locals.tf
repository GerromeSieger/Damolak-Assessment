locals {
  env_map = merge(
    {
      PORT       = tostring(var.app_port)
      AWS_REGION = var.region
      NODE_ENV   = var.environment == "prod" ? "production" : "development"
    },
    var.app_env
  )

  env = [
    for key, value in local.env_map : {
      name  = key
      value = value
    }
  ]

  # Only API_BASE_URL is injected from Secrets Manager
  env_secrets = sensitive([
    {
      name      = "API_BASE_URL"
      valueFrom = "${aws_secretsmanager_secret.app.arn}:API_BASE_URL::"
    }
  ])
}
