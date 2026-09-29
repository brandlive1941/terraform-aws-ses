data "aws_region" "current" {}

resource "aws_sesv2_configuration_set" "this" {
  for_each = var.configuration_sets

  configuration_set_name = each.key
  tags                   = each.value.tags

  delivery_options {
    tls_policy           = each.value.tls_policy
    max_delivery_seconds = each.value.max_delivery_seconds
    sending_pool_name    = each.value.sending_pool_name
  }

  reputation_options {
    reputation_metrics_enabled = each.value.reputation_metrics_enabled
  }

  sending_options {
    sending_enabled = each.value.sending_enabled
  }
}

resource "aws_sesv2_email_identity" "this" {
  for_each = var.email_identities

  email_identity         = each.key
  configuration_set_name = each.value.configuration_set_name
  tags                   = each.value.tags

  # Omitted entirely for Easy DKIM so AWS keeps issuing and rotating the keys.
  # Only BYODKIM callers materialise this block.
  dynamic "dkim_signing_attributes" {
    for_each = each.value.dkim == null ? [] : [each.value.dkim]
    content {
      domain_signing_private_key = dkim_signing_attributes.value.private_key
      domain_signing_selector    = dkim_signing_attributes.value.selector
    }
  }

  depends_on = [aws_sesv2_configuration_set.this]
}

resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  for_each = {
    for name, cfg in var.email_identities : name => cfg
    if cfg.mail_from_domain != null
  }

  email_identity         = aws_sesv2_email_identity.this[each.key].email_identity
  mail_from_domain       = each.value.mail_from_domain
  behavior_on_mx_failure = each.value.mail_from_on_mx_failure
}
