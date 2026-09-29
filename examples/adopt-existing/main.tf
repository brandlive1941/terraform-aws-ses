// Adopting SES identities that were created by hand in the console.
//
// The first plan must show only imports plus default_tags additions. A destroy,
// a replace, or an in-place change to anything else means the config does not
// match the live resource — fix the config, not the resource.

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "ses" {
  source = "github.com/brandlive1941/terraform-aws-ses?ref=v1.0.0"

  configuration_sets = {
    # Left at the SES defaults so adoption is a no-op. Turning reputation
    # metrics on is a separate, deliberate change.
    default = {}
  }

  email_identities = {
    "example.com" = {
      configuration_set_name = "default"
      mail_from_domain       = "mail.example.com"
      tags                   = { env = "dev" }
    }
  }
}

import {
  to = module.ses.aws_sesv2_configuration_set.this["default"]
  id = "default"
}

import {
  to = module.ses.aws_sesv2_email_identity.this["example.com"]
  id = "example.com"
}

import {
  to = module.ses.aws_sesv2_email_identity_mail_from_attributes.this["example.com"]
  id = "example.com"
}

# Publish these in whichever zone actually hosts the domain — this module does
# not manage DNS.
output "dns_records_to_publish" {
  value = {
    dkim      = module.ses.dkim_dns_records
    mail_from = module.ses.mail_from_dns_records
  }
}
