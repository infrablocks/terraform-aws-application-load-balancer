variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "idle_timeout" {
  type = number
  default = null
}

variable "expose_to_public_internet" {
  type = bool
  default = null
}

variable "security_groups" {
  type = object({
    default: object({
      associate: optional(bool),
      ingress_rule: optional(object({
        include: optional(bool),
        cidrs: optional(list(string))
      })),
      egress_rule: object({
        include: optional(bool),
        from_port: optional(number),
        to_port: optional(number),
        cidrs: optional(list(string))
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
    protocol: optional(string),
    target_type: optional(string),
    deregistration_delay: optional(number),
    health_check: object({
      path: optional(string),
      port: optional(string),
      protocol: optional(string),
      interval: optional(number),
      healthy_threshold: optional(number),
      unhealthy_threshold: optional(number)
    })
  }))
  default = null
}

variable "listeners" {
  type = list(object({
    key: string,
    port: optional(string),
    protocol: optional(string),
    ssl_policy: optional(string),
    certificate_arn: optional(string),
    default_actions: list(object({
      type: optional(string)
      target_group_key: optional(string)
      authorization_endpoint: optional(string)
      client_id: optional(string)
      client_secret: optional(string)
      issuer: optional(string)
      token_endpoint: optional(string)
      user_info_endpoint: optional(string)
      authentication_request_extra_params: optional(map(string))
      on_unauthenticated_request: optional(string)
      scope: optional(string)
      session_cookie_name: optional(string)
      session_timeout: optional(number)
    }))
  }))
  default = null
}
