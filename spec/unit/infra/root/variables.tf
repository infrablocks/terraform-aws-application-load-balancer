variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "idle_timeout" {
  type = number
  default = null
}

variable "expose_to_public_internet" {
  default = null
}

variable "security_groups" {
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
  default = null
}

variable "dns" {
  type = object({
    domain_name: string,
    records: list(object({zone_id: string}))
  })
  default = null
}

variable "target_groups" {
  type = list(object({
    key: string,
    port: string,
    protocol: string,
    target_type: string,
    health_check: object({
      path: string,
      port: string,
      protocol: string,
      interval: number,
      healthy_threshold: number,
      unhealthy_threshold: number
    })
  }))
  default = null
}

variable "listeners" {
  type = list(object({
    key: string,
    port: string,
    protocol: string,
    ssl_policy: string,
    certificate_arn: string,
    default_action: object({
      type: string,
      target_group_key: string
    })
  }))
  default = null
}
