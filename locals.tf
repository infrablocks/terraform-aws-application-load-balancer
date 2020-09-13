locals {
  security_groups = {
    default: {
      associate: lookup(var.security_groups.default, "associate", "yes"),
      ingress_rule: {
        include: lookup(var.security_groups.default.ingress_rule, "include", "yes"),
        cidrs: lookup(var.security_groups.default.ingress_rule, "cidrs", [data.aws_vpc.vpc.cidr_block]),
      },
      egress_rule: {
        include: lookup(var.security_groups.default.egress_rule, "include", "yes"),
        from_port: lookup(var.security_groups.default.egress_rule, "from_port", "0"),
        to_port: lookup(var.security_groups.default.egress_rule, "to_port", "0"),
        cidrs: lookup(var.security_groups.default.egress_rule, "cidrs", [data.aws_vpc.vpc.cidr_block]),
      }
    }
  }

  dns = {
    domain_name: var.dns.domain_name,
    records: {
      for record in lookup(var.dns, "records", []) : record.zone_id => record
    }
  }

  target_groups = {
    for target_group in var.target_groups : target_group.key => {
      key = target_group.key,
      port = target_group.port,
      protocol = lookup(target_group, "protocol", "HTTP"),
      target_type = lookup(target_group, "target_type", "instance"),
      health_check = {
        port = lookup(target_group.health_check, "port", "traffic-port")
        protocol = lookup(target_group.health_check, "protocol", "HTTP"),
        interval = lookup(target_group.health_check, "interval", 30),
        healthy_threshold = lookup(target_group.health_check, "healthy_threshold", 3),
        unhealthy_threshold = lookup(target_group.health_check, "unhealthy_threshold", 3),
      }
    }
  }

  listeners = {
    for listener in var.listeners : listener.key => {
      key = listener.key,
      port = lookup(listener, "port", 443),
      protocol = lookup(listener, "protocol", "HTTPS"),
      certificate_arn = listener.certificate_arn,
      default_action = {
        type = lookup(listener.default_action, "type", "forward"),
        target_group_key = lookup(listener.default_action, "target_group_key", null),
      }
    }
  }

  target_groups_output = {
    for target_group in var.target_groups : target_group.key => {
      id = aws_lb_target_group.target_group[target_group.key].id,
      name = aws_lb_target_group.target_group[target_group.key].name,
      arn = aws_lb_target_group.target_group[target_group.key].arn,
      arn_suffix = aws_lb_target_group.target_group[target_group.key].arn_suffix,
    }
  }

  listeners_output = {
    for listener in var.listeners : listener.key => {
      arn = aws_lb_listener.listener[listener.key].arn,
      certificate_arn = aws_lb_listener.listener[listener.key].certificate_arn
    }
  }
}
