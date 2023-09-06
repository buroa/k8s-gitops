# Cache Settings
resource "cloudflare_ruleset" "cache_settings" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "Cache"
  description = "Cache settings"
  kind        = "zone"
  phase       = "http_request_cache_settings"

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
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = false
    }
    description = "Set cache settings for plex.ktwo.io: bypass"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/(.+)/notifications(.*)\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/(video|subtitles)/:/transcode/(.*)\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/library/parts/(.+)/(.+)/(.+)\")"
  }
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
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 60
        mode    = "override_origin"
      }
      cache = true
      edge_ttl {
        default = 300
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: streams"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/library/streams/(.*)\")"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 300
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        cache_deception_armor = false
        custom_key {
          query_string {
            exclude = ["X-Plex-Client-Identifier", "X-Plex-Client-Profile-Name", "X-Plex-Device-Name", "X-Plex-Device-Screen-Resolution", "X-Plex-Drm", "X-Plex-Features", "X-Plex-Language", "X-Plex-Model", "X-Plex-Platform-Version", "X-Plex-Platform", "X-Plex-Product", "X-Plex-Provider-Version", "X-Plex-Session-Identifier", "X-Plex-Text-Format", "X-Plex-Token", "X-Plex-Version", "X-Plex-Advertising-Identifier", "X-Plex-Device", "X-Plex-Device-Vendor", "Accept-Language"]
          }
        }
        ignore_query_strings_order = false
      }
      edge_ttl {
        default = 2678400
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: metadata"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/library/metadata/(.+)/\" and not http.request.uri.path matches \"/library/metadata/(.+)/(thumb|art)/(.+)\")"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 14400
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        custom_key {
          query_string {
            exclude = ["X-Plex-Client-Identifier", "X-Plex-Client-Profile-Name", "X-Plex-Device-Name", "X-Plex-Device-Screen-Resolution", "X-Plex-Drm", "X-Plex-Features", "X-Plex-Language", "X-Plex-Model", "X-Plex-Platform-Version", "X-Plex-Platform", "X-Plex-Product", "X-Plex-Provider-Version", "X-Plex-Session-Identifier", "X-Plex-Text-Format", "X-Plex-Token", "X-Plex-Version", "X-Plex-Advertising-Identifier", "X-Plex-Device", "X-Plex-Device-Vendor", "Accept-Language"]
          }
        }
      }
      edge_ttl {
        default = 86400
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: collections"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path contains \"/library/collections\")"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 300
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        custom_key {
          query_string {
            exclude = ["X-Plex-Client-Identifier", "X-Plex-Client-Profile-Name", "X-Plex-Device-Name", "X-Plex-Device-Screen-Resolution", "X-Plex-Drm", "X-Plex-Features", "X-Plex-Language", "X-Plex-Model", "X-Plex-Platform-Version", "X-Plex-Platform", "X-Plex-Product", "X-Plex-Provider-Version", "X-Plex-Session-Identifier", "X-Plex-Text-Format", "X-Plex-Token", "X-Plex-Version", "X-Plex-Advertising-Identifier", "X-Plex-Device", "X-Plex-Device-Vendor", "Accept-Language"]
          }
        }
      }
      edge_ttl {
        default = 2678400
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: sections"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/library/sections/(.+)/\")"
  }
  rules {
    action = "set_cache_settings"
    action_parameters {
      browser_ttl {
        default = 300
        mode    = "override_origin"
      }
      cache = true
      cache_key {
        custom_key {
          query_string {
            exclude = ["X-Plex-Client-Identifier", "X-Plex-Client-Profile-Name", "X-Plex-Device-Name", "X-Plex-Device-Screen-Resolution", "X-Plex-Drm", "X-Plex-Features", "X-Plex-Language", "X-Plex-Model", "X-Plex-Platform-Version", "X-Plex-Platform", "X-Plex-Product", "X-Plex-Provider-Version", "X-Plex-Session-Identifier", "X-Plex-Text-Format", "X-Plex-Token", "X-Plex-Version", "X-Plex-Advertising-Identifier", "X-Plex-Device-Vendor", "X-Plex-Device", "Accept-Language"]
          }
        }
      }
      edge_ttl {
        default = 2678400
        mode    = "override_origin"
      }
    }
    description = "Set cache settings for plex.ktwo.io: hub"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path contains \"/hubs/sections\" and not http.request.uri.path matches \"/hubs/sections/(.+)/continueWatching\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/hubs/metadata/(.+)/related\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/hubs/home/recentlyAdded\") or (http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/hubs/promoted\")"
  }
}
