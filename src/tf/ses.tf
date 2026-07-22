locals {
  ses_email_identity   = "levizitting.com"
  ses_mail_from_domain = "bounce.${local.ses_email_identity}"
}

resource "aws_sesv2_email_identity" "levizitting_com" {
  email_identity = local.ses_email_identity

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "levizitting_com" {
  email_identity = aws_sesv2_email_identity.levizitting_com.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = local.ses_mail_from_domain
}
