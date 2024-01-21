resource "cloudflare_ruleset" "waf_custom_rules" {
  zone_id = var.zone_id
  name    = "Zone custom WAF ruleset"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  dynamic "rules" {
    for_each = var.waf_custom_rules
    iterator = rule
    content {
      enabled     = rule.value.enabled
      description = rule.value.description
      expression  = rule.value.expression
      action      = rule.value.action
    }
  }
}
