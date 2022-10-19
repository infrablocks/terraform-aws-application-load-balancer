locals {
  # default for cases when `null` value provided, meaning "use default"
  idle_timeout              = var.idle_timeout == null ? 60 : var.idle_timeout
  expose_to_public_internet = var.expose_to_public_internet == null ? "no" : var.expose_to_public_internet

  raw_associate_default_security_group             = try(var.security_groups.default.associate, null)
  raw_include_default_security_group_ingress_rule  = try(var.security_groups.default.ingress_rule.include, null)
  raw_include_default_security_group_egress_rule   = try(var.security_groups.default.egress_rule.include, null)
  raw_default_security_group_ingress_rule_cidrs    = try(var.security_groups.default.ingress_rule.cidrs, null)
  raw_default_security_group_egress_rule_cidrs     = try(var.security_groups.default.egress_rule.cidrs, null)
  raw_default_security_group_egress_rule_from_port = try(var.security_groups.default.egress_rule.from_port, null)
  raw_default_security_group_egress_rule_to_port   = try(var.security_groups.default.egress_rule.to_port, null)

  associate_default_security_group             = local.raw_associate_default_security_group == null ? "yes" : local.raw_associate_default_security_group
  include_default_security_group_ingress_rule  = local.raw_include_default_security_group_ingress_rule == null ? "yes" : local.raw_include_default_security_group_ingress_rule
  include_default_security_group_egress_rule   = local.raw_include_default_security_group_egress_rule == null ? "yes" : local.raw_include_default_security_group_egress_rule
  default_security_group_ingress_rule_cidrs    = local.raw_default_security_group_ingress_rule_cidrs == null ? [
    data.aws_vpc.vpc.cidr_block
  ] : local.raw_default_security_group_ingress_rule_cidrs
  default_security_group_egress_rule_cidrs     = local.raw_default_security_group_egress_rule_cidrs == null ? [
    data.aws_vpc.vpc.cidr_block
  ] : local.raw_default_security_group_egress_rule_cidrs
  default_security_group_egress_rule_from_port = local.raw_default_security_group_egress_rule_from_port == null ? 0 : local.raw_default_security_group_egress_rule_from_port
  default_security_group_egress_rule_to_port   = local.raw_default_security_group_egress_rule_to_port == null ? 65535 : local.raw_default_security_group_egress_rule_to_port

  security_groups = {
    default : {
      associate : local.associate_default_security_group
      ingress_rule : {
        include : local.include_default_security_group_ingress_rule,
        cidrs : local.default_security_group_ingress_rule_cidrs,
      },
      egress_rule : {
        include : local.include_default_security_group_egress_rule,
        from_port : local.default_security_group_egress_rule_from_port,
        to_port : local.default_security_group_egress_rule_to_port,
        cidrs : local.default_security_group_egress_rule_cidrs,
      }
    }
  }

  dns = {
    domain_name : try(var.dns.domain_name, null),
    records : {
    for record in try(var.dns.records, []) : record.zone_id => record
    }
  }

  target_groups = {
  for target_group in (var.target_groups == null ? [] : var.target_groups) : target_group.key => {
    key                  = target_group.key,
    port                 = target_group.port,
    protocol             = try(target_group.protocol, null) == null ? "HTTP" : try(target_group.protocol, null),
    target_type          = try(target_group.target_type, null) == null ? "instance" : try(target_group.target_type, null),
    deregistration_delay = try(target_group.deregistration_delay, null),
    health_check         = {
      path                = try(target_group.health_check.path, null) == null ? "/" : try(target_group.health_check.path, null)
      port                = try(target_group.health_check.port, null) == null ? "traffic-port" : try(target_group.health_check.port, null)
      protocol            = try(target_group.health_check.protocol, null) == null ? "HTTP" : try(target_group.health_check.protocol, null),
      interval            = try(target_group.health_check.interval, null) == null ? 30 : try(target_group.health_check.interval, null),
      healthy_threshold   = try(target_group.health_check.healthy_threshold, null) == null ? 3 : try(target_group.health_check.healthy_threshold, null),
      unhealthy_threshold = try(target_group.health_check.unhealthy_threshold, null) == null ? 3 : try(target_group.health_check.unhealthy_threshold, null)
    }
  }
  }

  listeners = {
  for listener in (var.listeners == null ? [] : var.listeners) : listener.key => {
    key             = listener.key,
    port            = try(listener.port, null) == null ? 443 : try(listener.port, null),
    protocol        = try(listener.protocol, null) == null ? "HTTPS" : try(listener.protocol, null),
    certificate_arn = listener.certificate_arn,
    ssl_policy      = try(listener.ssl_policy, null) == null ? "ELBSecurityPolicy-2016-08" : try(listener.ssl_policy, null),
    default_action  = {
      type             = try(listener.default_action.type, null) == null ? "forward" : try(listener.default_action.type, null),
      target_group_key = try(listener.default_action.target_group_key, null),
    }
  }
  }
}
