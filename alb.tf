resource "aws_lb" "load_balancer" {
  load_balancer_type = "application"

  name = "${var.component}-${var.deployment_identifier}"
  subnets = var.subnet_ids
  security_groups = local.security_groups.default.associate == "yes" ? [aws_security_group.default["default"].id] : null

  internal = var.expose_to_public_internet == "yes" ? false : true

  idle_timeout = var.idle_timeout

  tags = {
    Name = "${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}
