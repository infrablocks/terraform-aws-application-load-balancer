variable "region" {
  description = "The region into which to deploy the load balancer."
  type = string
}

variable "vpc_id" {
  description = "The ID of the VPC into which to deploy the load balancer."
  type = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets for the ALB."
  type = list(string)
}

variable "component" {
  description = "The component for which the load balancer is being created."
  type = string
}

variable "deployment_identifier" {
  description = "An identifier for this instantiation."
  type = string
}

variable "idle_timeout" {
  description = "The time after which idle connections are closed."
  type = number
  nullable = false
  default = 60
}

variable "expose_to_public_internet" {
  description = "Whether or not to the ALB should be internet facing."
  type = bool
  nullable = false
  default = false
}

variable "security_groups" {
  description = "Details of security groups to add to the ALB, including the default security group."
  type = object({
    default: object({
      associate: optional(bool, true),
      ingress_rule: optional(object({
        include: optional(bool, true),
        cidrs: optional(list(string))
      }), {
        include: true,
        cidrs: null
      }),
      egress_rule: optional(object({
        include: optional(bool, true),
        from_port: optional(number, 0),
        to_port: optional(number, 65535),
        cidrs: optional(list(string))
      }), {
        include: true,
        from_port: 0,
        to_port: 65535,
        cidrs: null
      }),
    })
  })
  nullable = false
  default = {
    default: {}
  }
}

variable "dns" {
  description = "Details of DNS records to point at the created load balancer. Expects a domain_name, used to create each record and a list of records to create. Each record object includes a zone_id referencing the hosted zone in which to create the record."
  type = object({
    domain_name: string,
    records: list(object({
      zone_id: string
    }))
  })
  nullable = false
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
    protocol: optional(string, "HTTP"),
    target_type: optional(string, "instance"),
    deregistration_delay: optional(number),
    health_check: optional(object({
      path: optional(string, "/"),
      port: optional(string, "traffic-port"),
      protocol: optional(string, "HTTP"),
      interval: optional(number, 30),
      healthy_threshold: optional(number, 3),
      unhealthy_threshold: optional(number, 3)
    }), {})
  }))
  nullable = false
  default = []
}

variable "listeners" {
  description = "Details of listeners to create."
  type = list(object({
    key: string,
    port: optional(string, "443"),
    protocol: optional(string, "HTTPS"),
    certificate_arn: optional(string),
    ssl_policy: optional(string, "ELBSecurityPolicy-2016-08"),
    default_action: object({
      type: optional(string, "forward"),
      target_group_key: optional(string)
    })
  }))
  nullable = false
  default = []
}
