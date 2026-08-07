resource "aws_lb" "load_balancer" {
  name               = var.name
  load_balancer_type = "application"

  subnets = var.subnet_ids
  security_groups = var.security_groups.default.associate ? [aws_security_group.default["default"].id] : null

  internal = !var.expose_to_public_internet

  idle_timeout = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [var.access_logs] : []
    content {
      enabled = true
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
    }
  }

  tags = {
    Name = "${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}
