terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

resource "cloudflare_tiered_cache" "tiered_cache" {
  zone_id    = var.zone_id
  cache_type = "smart"
}

resource "cloudflare_regional_tiered_cache" "regional_tiered_cache" {
  zone_id = var.zone_id
  value   = "on"
}

resource "cloudflare_zone_cache_reserve" "zone_cache_reserve" {
  zone_id = var.zone_id
  enabled = true
}

resource "cloudflare_argo" "argo" {
  zone_id       = var.zone_id
  smart_routing = "on"
}

resource "cloudflare_authenticated_origin_pulls" "authenticated_origin_pulls" {
  zone_id = var.zone_id
  enabled = true
}
