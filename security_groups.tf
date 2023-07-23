resource "aws_security_group" "default" {
  for_each = var.security_groups.default.associate ? var.security_groups : {}

  name = "${var.component}-${var.deployment_identifier}"
  description = "ALB security group for: ${var.component}, deployment: ${var.deployment_identifier}"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

resource "aws_security_group_rule" "default_ingress" {
  for_each = var.security_groups.default.associate && var.security_groups.default.ingress_rule.include ? {
    for listener in var.listeners : listener.key => listener
  } : {}

  type = "ingress"

  security_group_id = aws_security_group.default["default"].id

  protocol = "tcp"
  from_port = each.value.port
  to_port = each.value.port

  cidr_blocks = coalesce(var.security_groups.default.ingress_rule.cidrs, [data.aws_vpc.vpc.cidr_block])
}

resource "aws_security_group_rule" "default_egress" {
  for_each = var.security_groups.default.associate && var.security_groups.default.egress_rule.include ? var.security_groups : {}

  type = "egress"

  security_group_id = aws_security_group.default["default"].id

  protocol = "tcp"
  from_port = each.value.egress_rule.from_port
  to_port = each.value.egress_rule.to_port

  cidr_blocks = coalesce(each.value.egress_rule.cidrs, [data.aws_vpc.vpc.cidr_block])
}
