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

variable "security_groups" {
  description = "Details of security groups to add to the ALB, including the default security group."
  type = object({
    default: object({
      associate: string,
      ingress_rule: object({
        include: string,
        cidrs: list(string)
      }),
      egress_rule: object({
        include: string,
        from_port: number,
        to_port: number,
        cidrs: list(string)
      }),
    })
  })
  default = {
    default: {
      associate: "yes"
      ingress_rule: {
        include: "yes",
        cidrs: null
      },
      egress_rule: {
        include: "yes",
        from_port: 0,
        to_port: 65535,
        cidrs: null
      }
    }
  }
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
    deregistration_delay: optional(number),
    health_check: object({
      path: string,
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
    ssl_policy: string,
    default_action: object({
      type: string,
      target_group_key: string
    })
  }))
  default = []
}
