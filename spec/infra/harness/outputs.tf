output "vpc_id" {
  value = module.application_load_balancer.vpc_id
}

output "name" {
  value = module.application_load_balancer.name
}

output "arn" {
  value = module.application_load_balancer.arn
}

output "zone_id" {
  value = module.application_load_balancer.zone_id
}

output "dns_name" {
  value = module.application_load_balancer.dns_name
}

output "address" {
  value = module.application_load_balancer.address
}

output "target_groups" {
  value = module.application_load_balancer.target_groups
}

output "listeners" {
  value = module.application_load_balancer.listeners
}
