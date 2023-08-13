# Enable Argo
resource "cloudflare_argo" "domain_argo" {
  zone_id        = data.cloudflare_zone.domain.id
  tiered_caching = "on"
  smart_routing  = "on"
}

# Enable Tiered Cache
resource "cloudflare_tiered_cache" "domain_tiered_cache" {
  zone_id    = data.cloudflare_zone.domain.id
  cache_type = "smart"
}

# Enable Regional Tiered Cache
resource "cloudflare_regional_tiered_cache" "domain_regional_tiered_cache" {
  zone_id = data.cloudflare_zone.domain.id
  value   = "on"
}

# Enable AOP
resource "cloudflare_authenticated_origin_pulls" "authenticated_origin_pulls" {
  zone_id = data.cloudflare_zone.domain.id
  enabled = true
}
