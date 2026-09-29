variable "configuration_sets" {
  description = <<-EOT
    SES v2 configuration sets, keyed by name.

    Defaults deliberately match what SES creates for you, so adopting a
    console-made set produces a no-op plan. Enabling reputation metrics is a
    change, not a default.
  EOT
  type = map(object({
    reputation_metrics_enabled = optional(bool, false)
    sending_enabled            = optional(bool, true)
    tls_policy                 = optional(string, "OPTIONAL")
    max_delivery_seconds       = optional(number)
    sending_pool_name          = optional(string)
    tags                       = optional(map(string), {})
  }))
  default = {}
}

variable "email_identities" {
  description = <<-EOT
    SES v2 email identities, keyed by identity name — either a domain
    (`example.com`) or a single address (`someone@example.com`).

    `mail_from_domain = null` keeps the default amazonses.com envelope sender.
    Supply `dkim` only for BYODKIM; leaving it null uses Easy DKIM, where AWS
    issues the tokens and you publish the CNAMEs from `dkim_dns_records`.
  EOT
  type = map(object({
    configuration_set_name  = optional(string)
    mail_from_domain        = optional(string)
    mail_from_on_mx_failure = optional(string, "USE_DEFAULT_VALUE")
    tags                    = optional(map(string), {})

    dkim = optional(object({
      private_key = string
      selector    = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for cfg in var.email_identities :
      contains(["USE_DEFAULT_VALUE", "REJECT_MESSAGE"], cfg.mail_from_on_mx_failure)
    ])
    error_message = "mail_from_on_mx_failure must be USE_DEFAULT_VALUE or REJECT_MESSAGE."
  }
}
