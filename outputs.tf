output "email_identity_arns" {
  description = "Identity ARNs, keyed by identity name."
  value       = { for k, v in aws_sesv2_email_identity.this : k => v.arn }
}

output "verified_for_sending" {
  description = <<-EOT
    Whether each identity can currently send. Read this rather than assuming —
    an identity whose DKIM CNAMEs were never published reads `false` here while
    looking present in the console.
  EOT
  value       = { for k, v in aws_sesv2_email_identity.this : k => v.verified_for_sending_status }
}

output "configuration_set_arns" {
  description = "Configuration set ARNs, keyed by name."
  value       = { for k, v in aws_sesv2_configuration_set.this : k => v.arn }
}

output "dkim_tokens" {
  description = "Easy DKIM tokens, keyed by identity name. Empty for address identities."
  value = {
    for k, v in aws_sesv2_email_identity.this :
    k => try(v.dkim_signing_attributes[0].tokens, [])
  }
}

output "dkim_dns_records" {
  description = <<-EOT
    CNAME records to publish for Easy DKIM, keyed by identity name.

    This module does not manage DNS — Brandlive's zones are split between
    Cloudflare and Route53 — so these are emitted for you to publish wherever
    the zone actually lives. Domain identities only; address identities yield
    an empty list.
  EOT
  value = {
    for k, v in aws_sesv2_email_identity.this :
    k => [
      for token in try(v.dkim_signing_attributes[0].tokens, []) : {
        name  = "${token}._domainkey.${k}"
        type  = "CNAME"
        value = "${token}.dkim.amazonses.com"
      }
    ] if v.identity_type == "DOMAIN"
  }
}

output "mail_from_dns_records" {
  description = <<-EOT
    MX and SPF records required for each custom MAIL FROM domain, keyed by
    identity name. Without both published, mail either falls back to the
    amazonses.com envelope sender or is rejected, depending on
    `mail_from_on_mx_failure`.
  EOT
  value = {
    for k, v in aws_sesv2_email_identity_mail_from_attributes.this :
    k => [
      {
        name  = v.mail_from_domain
        type  = "MX"
        value = "10 feedback-smtp.${data.aws_region.current.region}.amazonses.com"
      },
      {
        name  = v.mail_from_domain
        type  = "TXT"
        value = "v=spf1 include:amazonses.com ~all"
      },
    ]
  }
}
