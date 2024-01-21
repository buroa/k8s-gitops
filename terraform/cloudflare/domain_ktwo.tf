module "cf_domain_ktwo" {
  source     = "./modules/cf_domain"
  zone_id    = module.onepassword_item_cloudflare.fields["CLOUDFLARE_ZONE_ID"]
  account_id = module.onepassword_item_cloudflare.fields["CLOUDFLARE_ACCOUNT_ID"]

  dns_entries = [
    # Generic settings
    {
      id   = "caa_iodef"
      name = "@"
      data = {
        flags = "0"
        tag   = "iodef"
        value = "mailto:skre@skre.me"
      }
      type = "CAA"
    },
    {
      id   = "caa_issue"
      name = "@"
      data = {
        flags = "0"
        tag   = "issue"
        value = "letsencrypt.org"
      }
      type = "CAA"
    },
    {
      name  = "_dmarc"
      value = "v=DMARC1; p=quarantine;"
      type  = "TXT"
    },

    # Sendgrid settings
    {
      id      = "sendgrid_verify"
      name    = "em6256"
      value   = "u32664962.wl213.sendgrid.net"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "sendgrid_dkim_1"
      name    = "s1._domainkey"
      value   = "s1.domainkey.u32664962.wl213.sendgrid.net"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "sendgrid_dkim_2"
      name    = "s2._domainkey"
      value   = "s2.domainkey.u32664962.wl213.sendgrid.net"
      type    = "CNAME"
      proxied = false
    },
    {
      id    = "sendgrid_spf"
      name  = "@"
      value = "v=spf1 include:sendgrid.net -all"
      type  = "TXT"
    },

    # Tunnel settings
    {
      id      = "ingress"
      name    = "external"
      value   = "${module.onepassword_item_cloudflare.fields["CLOUDFLARE_TUNNEL_ID"]}.cfargotunnel.com"
      type    = "CNAME"
      proxied = true
    },
  ]

  cache_custom_rules = [
    # Plex
    {
      description = "Set cache settings for plex.ktwo.io: bypass"
      expression  = "(http.host eq \"plex.ktwo.io\" and (http.request.uri.path matches \"/(.+)/notifications(.*)\" or http.request.uri.path matches \"/(video|subtitles)/:/transcode/(.*)\" or http.request.uri.path matches \"/library/parts/(.+)/(.+)/(.+)\"))"
      action_parameters = {
        cache = false
      }
    },
    {
      description = "Set cache settings for plex.ktwo.io: image"
      expression  = "(http.host eq \"plex.ktwo.io\" and (http.request.uri.path matches \"^/library/.+/[0-9]*/.+/[0-9]*$\" or http.request.uri.path contains \"/:/resources/category-art\"))"
      action_parameters = {
        browser_ttl = {
          default = 16070400
        }
        edge_ttl = {
          default = 31536000
        }
        cache_key = {
          custom_key = {
            query_string = {
              exclude = ["*"]
            }
          }
        }
      }
    },
    {
      description = "Set cache settings for plex.ktwo.io: image transcoder"
      expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path matches \"/photo/:/transcode/(.*)\")"
      action_parameters = {
        browser_ttl = {
          default = 16070400
        }
        edge_ttl = {
          default = 31536000
        }
        cache_key = {
          custom_key = {
            query_string = {
              include = ["width", "height", "blur", "opacity", "background", "url"]
            }
          }
        }
      }
    },

    # Overseerr
    {
      description = "Set cache settings for requests.ktwo.io"
      expression  = "(http.host eq \"requests.ktwo.io\" and http.request.uri.path matches \"/_next/(image|static)/(.*)\")"
      action_parameters = {
        browser_ttl = {
          default = 16070400
        }
        edge_ttl = {
          default = 31536000
        }
      }
    },

    # Tautulli
    {
      description = "Set cache settings for tautulli.ktwo.io"
      expression  = "(http.host eq \"tautulli.ktwo.io\" and http.request.uri.path matches \"^/(newsletter|image|pms_image_proxy)\")"
      action_parameters = {
        browser_ttl = {
          default = 16070400
        }
        edge_ttl = {
          default = 31536000
        }
      }
    },
  ]

  transform_custom_rules = [
    # Plex
    {
      description = "Strip localhost from plex image transcoder"
      expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/photo/:/transcode\" and http.request.uri.query matches \"url=http%3A%2F%2F127.0.0.1%3A32400\")"
      action_parameters = {
        uri = {
          query = {
            expression = "regex_replace(http.request.uri.query, \"http%3A%2F%2F127.0.0.1%3A32400\", \"\")"
          }
        }
      }
    },
    {
      description = "Rewrite default from plex image transcoder"
      expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path eq \"/photo/:/transcode\" and http.request.uri.query matches \"url=.*%2Flibrary%2F(.+)%2F([0-9]+)%2F(.+)%2F([0-9])[^&]*\")"
      action_parameters = {
        uri = {
          query = {
            expression = "regex_replace(http.request.uri.query, \"url=.*%2Flibrary%2F(.+)%2F([0-9]+)%2F(.+)%2F([0-9]+)[^&]*\", \"url=%2Flibrary%2F$${1}%2F$${2}%2F$${3}%2F$${4}\")"
          }
        }
      }
    }
  ]

  waf_custom_rules = [
    {
      description = "Firewall rule to block threats determined by CF"
      expression  = "(cf.threat_score gt 14)"
    },
    {
      description = "Firewall rule to allow Github access to flux-webhook",
      expression  = "(http.host eq \"flux-webhook.ktwo.io\" and ip.geoip.asnum eq 36459)"
      action      = "skip"
    },
    {
      description = "Firewall rule to allow everyone access to kromgo",
      expression  = "(http.host eq \"kromgo.ktwo.io\")",
      action      = "skip"
    },
    {
      description = "Firewall rule to allow everyone access to nostr",
      expression  = "(http.host eq \"nostr-relay.ktwo.io\")",
      action      = "skip"
    },
    {
      description = "Firewall rule to block bots determined by CF"
      expression  = "(cf.client.bot)"
    },
    {
      description = "Firewall rule to block certain countries"
      expression  = "(not ip.geoip.country in {\"US\" \"CA\" \"NZ\" \"GB\" \"AU\"})"
    },
    {
      description = "Firewall rule to block plex notifications"
      expression  = "(http.host eq \"plex.ktwo.io\" and http.request.uri.path contains \"/:/eventsource/notifications\")"
    },
  ]
}
