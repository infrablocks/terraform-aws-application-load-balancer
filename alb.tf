resource "aws_lb" "load_balancer" {
  load_balancer_type = "application"

  subnets = var.subnet_ids
  security_groups = var.security_groups.default.associate ? [aws_security_group.default["default"].id] : null

  internal = !var.expose_to_public_internet

  idle_timeout = var.idle_timeout

  tags = {
    Name = "${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}
