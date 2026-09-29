# terraform-aws-ses

Terraform module for Amazon SES v2 email identities, custom MAIL FROM domains, and
configuration sets.

## Why this exists rather than a registry module

Every widely-used SES module on the registry (`cloudposse/ses`,
`trussworks/ses-domain`, `babbel/ses-sending-domain`, `umotif-public/ses-domain`)
manages the DKIM and verification records **in Route53**. That only holds if
every zone you send from is hosted there. Where zones are split across DNS
providers, or managed outside Terraform entirely, a module that insists on
creating Route53 records is the wrong shape. Several also bundle an IAM user for
SMTP credentials, which is unwanted when sending uses task roles.

So this module manages SES and **only** SES, and emits the DNS records you need
as outputs for you to publish wherever the zone actually lives.

## Usage

```hcl
module "ses" {
  source = "github.com/brandlive1941/terraform-aws-ses?ref=v1.0.0"

  configuration_sets = {
    default = {}
  }

  email_identities = {
    "example.com" = {
      configuration_set_name = "default"
      mail_from_domain       = "mail.example.com"
    }
  }
}

output "dkim_records" {
  value = module.ses.dkim_dns_records
}
```

Then publish what `dkim_dns_records` and `mail_from_dns_records` give you in the
relevant zone. Until the DKIM CNAMEs exist, `verified_for_sending` stays `false`
and SES will not send for that identity.

## Adopting resources created by hand

The common case. Model the live resource exactly, then let `import` blocks adopt
it — the first plan must show no changes beyond `default_tags` additions.

```hcl
import {
  to = module.ses.aws_sesv2_email_identity.this["example.com"]
  id = "example.com"
}

import {
  to = module.ses.aws_sesv2_email_identity_mail_from_attributes.this["example.com"]
  id = "example.com"
}

import {
  to = module.ses.aws_sesv2_configuration_set.this["default"]
  id = "default"
}
```

Two adoption traps worth knowing, both found while importing the real estate:

- **`reputation_metrics_enabled` defaults to `false` in this module**, matching what
  SES itself creates. A module defaulting it to `true` silently turns metrics on
  during adoption. Set it explicitly when you actually want it.
- **Existing tags are yours to carry over.** If a console-created identity has
  tags, put them in `tags` or the first apply deletes them.

## Easy DKIM vs BYODKIM

Leave `dkim` unset for Easy DKIM — AWS issues and rotates the keys, and the
module doesn't touch the signing attributes at all. Supply `dkim` only when you
are bringing your own key:

```hcl
"example.com" = {
  dkim = {
    private_key = var.signing_key
    selector    = "mail"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `configuration_sets` | `map(object)` | `{}` | Configuration sets keyed by name |
| `email_identities` | `map(object)` | `{}` | Identities keyed by domain or address |

See [`variables.tf`](variables.tf) for the full object schemas.

## Outputs

| Name | Description |
|---|---|
| `email_identity_arns` | Identity ARNs, keyed by identity |
| `verified_for_sending` | Whether each identity can currently send |
| `configuration_set_arns` | Configuration set ARNs |
| `dkim_tokens` | Easy DKIM tokens, keyed by identity |
| `dkim_dns_records` | CNAMEs to publish for DKIM, ready to paste into the zone |
| `mail_from_dns_records` | MX + SPF records required per custom MAIL FROM domain |

## What this module does not do

- **DNS.** By design — see above.
- **Tenants.** SES tenant management (per-tenant reputation and suppression) is
  not modelled here yet.
- **Event destinations.** Configuration sets are created, but not their event
  destinations.
- **Account-level settings.** Production access, sending quotas and the
  account-level suppression list are not Terraform-managed.

## Requirements

| Name | Version |
|---|---|
| terraform | `>= 1.5.7` |
| aws | `>= 6.0` |
