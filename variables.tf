variable "region" {
  description = "The region into which to deploy the load balancer."
}

variable "vpc_id" {
  description = "The ID of the VPC into which to deploy the load balancer."
}

variable "subnet_ids" {
  description = "The IDs of the subnets for the ALB."
  type = list(string)
}

variable "component" {
  description = "The component for which the load balancer is being created."
}

variable "deployment_identifier" {
  description = "An identifier for this instantiation."
}

variable "idle_timeout" {
  description = "The time after which idle connections are closed."
  default = 60
}

variable "expose_to_public_internet" {
  description = "Whether or not to the ALB should be internet facing (\"yes\" or \"no\")."
  default = "no"
}

variable "dns" {
  description = "Details of DNS records to point at the created load balancer. Expects a domain_name, used to create each record and a list of records to create. Each record object includes a zone_id referencing the hosted zone in which to create the record."
  type = object({
    domain_name: string,
    records: list(object({zone_id: string}))
  })
  default = {
    domain_name: null,
    records: []
  }
}

variable "target_groups" {
  description = "Details of target groups to create."
  type = list(object({
    key: string,
    port: string,
    protocol: string,
    target_type: string,
    health_check: object({
      port: string,
      protocol: string,
      interval: number,
      healthy_threshold: number,
      unhealthy_threshold: number
    })
  }))
  default = []
}

variable "listeners" {
  description = "Details of listeners to create."
  type = list(object({
    key: string,
    port: string,
    protocol: string,
    certificate_arn: string,
    default_action: object({
      type: string,
      target_group_key: string
    })
  }))
  default = []
}
