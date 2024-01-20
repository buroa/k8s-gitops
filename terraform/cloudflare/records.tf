# General
resource "cloudflare_record" "general_caa_iodef" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  data {
    flags = "0"
    tag   = "iodef"
    value = "mailto:skre@skre.me"
  }
  type = "CAA"
  ttl  = 1
}

resource "cloudflare_record" "general_caa_issue" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  data {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
  type = "CAA"
  ttl  = 1
}

resource "cloudflare_record" "general_spf" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  value   = "v=spf1 include:sendgrid.net -all"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "general_dmarc" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=reject; pct=100; rua=mailto:skre@skre.me"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "sendgrid_auth" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "em6256"
  value   = "u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "sendgrid_dkim_1" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "s1._domainkey"
  value   = "s1.domainkey.u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "sendgrid_dkim_2" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "s2._domainkey"
  value   = "s2.domainkey.u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# Cloudflare Tunnel Ingress
resource "cloudflare_record" "external_ingress" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "external"
  value   = "${module.onepassword_item.fields["CLOUDFLARE_TUNNEL_ID"]}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# K8s (incase internal DNS is not available)
resource "cloudflare_record" "internal_k8s" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "k8s"
  value   = "10.0.0.2"
  type    = "A"
  proxied = false
  ttl     = 1
}
