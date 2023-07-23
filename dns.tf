resource "aws_route53_record" "load_balancer" {
  for_each = {
    for record in coalesce(var.dns.records, []) : record.zone_id => record
  }

  zone_id = each.value.zone_id
  name = "${var.component}-${var.deployment_identifier}.${var.dns.domain_name}"
  type = "A"

  alias {
    name = aws_lb.load_balancer.dns_name
    zone_id = aws_lb.load_balancer.zone_id
    evaluate_target_health = false
  }
}
