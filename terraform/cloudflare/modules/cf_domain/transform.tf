resource "cloudflare_ruleset" "transform_custom_rules" {
  zone_id = var.zone_id
  name    = "Zone custom transform ruleset"
  kind    = "zone"
  phase   = "http_request_transform"

  dynamic "rules" {
    for_each = var.transform_custom_rules
    iterator = rule
    content {
      enabled     = rule.value.enabled
      description = rule.value.description
      expression  = rule.value.expression
      action      = rule.value.action

      dynamic "action_parameters" {
        for_each = length(keys(rule.value.action_parameters)) > 0 ? [true] : []
        content {
          uri {
            query {
              expression = rule.value.action_parameters.uri.query.expression
            }
          }
        }
      }
    }
  }
}
