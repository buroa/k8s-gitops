# DNS Records

resource "cloudflare_record" "_32664962" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "32664962"
  value   = "sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "em6256" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "em6256"
  value   = "u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "s1" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "s1._domainkey"
  value   = "s1.domainkey.u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "s2" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "s2._domainkey"
  value   = "s2.domainkey.u32664962.wl213.sendgrid.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "url1742" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "url1742"
  value   = "sendgrid.net"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "caa_iodef" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  data    {
    flags  = "0"
    tag   = "iodef"
    value = "mailto:skre@skre.me"
  }
  type    = "CAA"
  ttl     = 1
}

resource "cloudflare_record" "caa_issue" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  data    {
    flags  = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
  type    = "CAA"
  ttl     = 1
}

resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.domain.id
  name    = data.cloudflare_zone.domain.name
  value   = "v=spf1 include:sendgrid.net -all"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "_dmarc" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=reject; pct=100; rua=mailto:skre@skre.me"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "k8s" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "k8s"
  value   = "10.0.0.2"
  type    = "A"
  proxied = false
  ttl     = 1
}

resource "cloudflare_record" "ingress" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "ingress"
  value   = "${module.onepassword_item.fields["tunnel-id"]}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}