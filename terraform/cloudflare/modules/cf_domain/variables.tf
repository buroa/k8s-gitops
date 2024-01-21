variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "enable_default_firewall_rules" {
  type    = bool
  default = true
}

variable "dns_entries" {
  type = list(object({
    id   = optional(string)
    name = string,
    data = optional(object({
      flags = string,
      tag   = string,
      value = string
    })),
    value    = optional(string),
    type     = optional(string, "A"),
    proxied  = optional(bool, true),
    priority = optional(number, 0),
    ttl      = optional(number, 1)
  }))
  default = []
}

variable "cache_custom_rules" {
  type = list(object({
    enabled     = optional(bool, true)
    description = string
    expression  = string
    action      = optional(string, "set_cache_settings")
    action_parameters = optional(object({
      browser_ttl = optional(object({
        default = number
        mode    = optional(string, "override_origin")
      })),
      cache = optional(bool, true),
      cache_key = optional(object({
        custom_key = optional(object({
          query_string = optional(object({
            exclude = optional(list(string)),
            include = optional(list(string))
          }))
        }))
      })),
      edge_ttl = optional(object({
        default = number
        mode    = optional(string, "override_origin")
      }))
    })),
  }))
  default = []
}

variable "transform_custom_rules" {
  type = list(object({
    enabled           = optional(bool, true)
    description       = string
    expression        = string
    action            = optional(string, "rewrite")
    action_parameters = optional(map(any))
  }))
  default = []
}

variable "waf_custom_rules" {
  type = list(object({
    enabled           = optional(bool, true)
    description       = string
    expression        = string
    action            = optional(string, "block")
  }))
  default = []
}
