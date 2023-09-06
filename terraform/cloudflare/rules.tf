# Plex Images
resource "cloudflare_ruleset" "plex_images_1" {
  kind    = "zone"
  name    = "Plex - Image Transcoder"
  phase   = "http_request_transform"
  zone_id = data.cloudflare_zone.domain.id

  rules {
    action = "rewrite"
    action_parameters {
      uri {
        query {
          expression = "regex_replace(http.request.uri.query, \"http%3A%2F%2F127.0.0.1%3A32400\", \"\")"
        }
      }
    }
    description = "Plex - Image Transcoder - Strip Localhost"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/photo/:/transcode\" and http.request.uri.query matches \"url=http%3A%2F%2F127.0.0.1%3A32400\")"
  }
  rules {
    action = "rewrite"
    action_parameters {
      uri {
        query {
          expression = "regex_replace(http.request.uri.query, \"url=.*%2Flibrary%2F(.+)%2F([0-9]+)%2F(.+)%2F([0-9]+)[^&]*\", \"url=%2Flibrary%2F$${1}%2F$${2}%2F$${3}%2F$${4}\")"
        }
      }
    }
    description = "Plex - Image Transcoder - Rewrite Default"
    enabled     = true
    expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/photo/:/transcode\" and http.request.uri.query matches \"url=.*%2Flibrary%2F(.+)%2F([0-9]+)%2F(.+)%2F([0-9])[^&]*\")"
  }
}

resource "cloudflare_page_rule" "plex_images_2" {
  priority = 1
  status   = "active"
  target   = "plex.ktwo.io/photo/:/transcode*"
  zone_id  = data.cloudflare_zone.domain.id

  actions {
    mirage = "on"
    polish = "lossy"
  }
}

resource "cloudflare_page_rule" "sendgrid_ssl" {
  priority = 2
  status   = "active"
  target   = "url1742.ktwo.io/*"
  zone_id  = data.cloudflare_zone.domain.id

  actions {
    ssl = "full"
  }
}
