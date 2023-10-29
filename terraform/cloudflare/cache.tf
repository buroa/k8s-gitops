# Cache Settings
resource "cloudflare_ruleset" "cache_settings" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Cache"
  description = "Cache settings"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  # Overseerr
  rules {
    action = "set_cache_settings"
    action_parameters {
      edge_ttl {
        mode    = "override_origin"
        default = 16070400
      }
      browser_ttl {
        mode    = "override_origin"
        default = 31536000
      }
    }
    expression  = "(http.host eq \"requests.ktwo.io\" and http.request.uri.path matches \"/_next/(image|static)/(.*)\")"
    description = "Set cache settings for requests.ktwo.io"
    enabled     = true
  }

  # Tautulli
  rules {
    action = "set_cache_settings"
    action_parameters {
      edge_ttl {
        mode    = "override_origin"
        default = 16070400
      }
      browser_ttl {
        mode    = "override_origin"
        default = 31536000
      }
    }
    expression  = "(http.host eq \"tautulli.ktwo.io\" and http.request.uri.path matches \"^/(newsletter|image|pms_image_proxy)\")"
    description = "Set cache settings for tautulli.ktwo.io"
    enabled     = true
  }

  # Bypass Plex
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = false
    }
    description = "Set cache settings for plex.ktwo.io: bypass"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/(.+)/notifications(.*)\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/(video|subtitles)/:/transcode/(.*)\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/library/parts/(.+)/(.+)/(.+)\")"
  }

  # Plex Images
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 16070400
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        custom_key {
          query_string {
            exclude = ["*"]
          }
        }
      }
      edge_ttl {
        default = 31536000
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: images"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"^/library/.+/[0-9]*/.+/[0-9]*$\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path contains \"/:/resources/category-art\")"
  }

  # Plex Images
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 16070400
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        custom_key {
          query_string {
            include = ["width", "height", "blur", "opacity", "background", "url"]
          }
        }
      }
      edge_ttl {
        default = 31536000
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: image transcoder"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path contains \"/photo/:/transcode\")"
  }
}
