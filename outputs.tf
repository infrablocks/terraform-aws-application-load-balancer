output "name" {
  description = "The name of the created ALB."
  value = aws_lb.load_balancer.name
}

output "vpc_id" {
  description = "The VPC ID of the created ALB."
  value = aws_lb.load_balancer.vpc_id
}

output "id" {
  description = "The id of the created ALB."
  value = aws_lb.load_balancer.id
}

output "arn" {
  description = "The ARN of the created ALB."
  value = aws_lb.load_balancer.arn
}

output "arn_suffix" {
  description = "The ARN suffix of the created ALB."
  value = aws_lb.load_balancer.arn_suffix
}

output "zone_id" {
  description = "The zone ID of the created ALB."
  value = aws_lb.load_balancer.zone_id
}

output "dns_name" {
  description = "The DNS name of the created ALB."
  value = aws_lb.load_balancer.dns_name
}

output "address" {
  description = "The address of the DNS record(s) for the created ALB."
  value = length(local.dns.records) > 0 ? "${var.component}-${var.deployment_identifier}.${local.dns.domain_name}" : ""
}

output "target_groups" {
  description = "Details of the created target groups."
  value = local.target_groups_output
}

output "listeners" {
  description = "Details pf the created listeners."
  value = local.listeners_output
}
