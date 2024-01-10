terraform {
  cloud {
    organization = "buroa"
    workspaces {
      name = "terraform-cloudflare"
    }
  }

  required_providers {
    onepassword = {
      source  = "1password/onepassword"
      version = "1.4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.22.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
  }

  required_version = ">= 1.3.0"
}

module "onepassword_item" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "K8s"
  item   = "cloudflare"
}

data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_zone" "domain" {
  name = "ktwo.io"
}
