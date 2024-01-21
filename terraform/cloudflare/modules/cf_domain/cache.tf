resource "cloudflare_ruleset" "cache_custom_rules" {
  zone_id = var.zone_id
  name    = "Zone custom cache ruleset"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  dynamic "rules" {
    for_each = var.cache_custom_rules
    iterator = rule
    content {
      enabled     = rule.value.enabled
      description = rule.value.description
      expression  = rule.value.expression
      action      = rule.value.action

      dynamic "action_parameters" {
        for_each = rule.value.action_parameters != null ? [true] : []
        content {
          dynamic "browser_ttl" {
            for_each = rule.value.action_parameters.browser_ttl != null ? [true] : []
            content {
              default = rule.value.action_parameters.browser_ttl.default
              mode    = rule.value.action_parameters.browser_ttl.mode
            }
          }
          cache = rule.value.action_parameters.cache
          dynamic "cache_key" {
            for_each = rule.value.action_parameters.cache_key != null ? [true] : []
            content {
              dynamic "custom_key" {
                for_each = rule.value.action_parameters.cache_key.custom_key != null ? [true] : []
                content {
                  dynamic "query_string" {
                    for_each = rule.value.action_parameters.cache_key.custom_key.query_string != null ? [true] : []
                    content {
                      exclude = rule.value.action_parameters.cache_key.custom_key.query_string.exclude
                      include = rule.value.action_parameters.cache_key.custom_key.query_string.include
                    }
                  }
                }
              }
            }
          }
          dynamic "edge_ttl" {
            for_each = rule.value.action_parameters.edge_ttl != null ? [true] : []
            content {
              default = rule.value.action_parameters.edge_ttl.default
              mode    = rule.value.action_parameters.edge_ttl.mode
            }
          }
        }
      }
    }
  }
}
