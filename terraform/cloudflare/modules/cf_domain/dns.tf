resource "cloudflare_record" "dns_records" {
  for_each = { for dns_entry in var.dns_entries : (dns_entry.id != null ? dns_entry.id : "${dns_entry.name}_${dns_entry.priority}") => dns_entry }

  name     = each.value.name
  zone_id  = var.zone_id
  dynamic "data" {
    for_each = each.value.data != null ? [true] : []
    content {
      flags  = each.value.data.flags
      tag   = each.value.data.tag
      value = each.value.data.value
    }
  }
  value    = each.value.value
  priority = each.value.priority
  proxied  = contains(["A", "CNAME"], each.value.type) ? each.value.proxied : false
  type     = each.value.type
  ttl      = each.value.ttl
}
