resource "aws_secretsmanager_secret" "app" {
  name                    = var.app_secret_name
  description             = "Secrets for web-app (${var.environment})"
  recovery_window_in_days = 7

  tags = { Name = var.app_secret_name }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    API_BASE_URL = "https://api.example.com"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
