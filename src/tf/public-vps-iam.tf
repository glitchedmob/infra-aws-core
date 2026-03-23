locals {
  public_vps_hostname                    = "x86-vps-node-01"
  public_vps_flux_iam_user_name          = "${local.public_vps_hostname}-flux-ssm"
  public_vps_flux_access_key_id_path     = "/homelab/${local.public_vps_hostname}/flux-ssm-access-key-id"
  public_vps_flux_secret_access_key_path = "/homelab/${local.public_vps_hostname}/flux-ssm-secret-access-key"
}

data "aws_caller_identity" "public_vps" {}

resource "aws_iam_user" "public_vps_flux_ssm" {
  name = local.public_vps_flux_iam_user_name
}

resource "aws_iam_user_policy" "public_vps_flux_ssm" {
  name = "${local.public_vps_flux_iam_user_name}-policy"
  user = aws_iam_user.public_vps_flux_ssm.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SsmDenyKeyParameters"
        Effect = "Deny"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.public_vps.account_id}:parameter${local.public_vps_flux_access_key_id_path}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.public_vps.account_id}:parameter${local.public_vps_flux_secret_access_key_path}"
        ]
      },
      {
        Sid    = "SsmReadScoped"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.public_vps.account_id}:parameter/homelab/${local.public_vps_hostname}/*"
      }
    ]
  })
}

resource "aws_iam_access_key" "public_vps_flux_ssm" {
  user = aws_iam_user.public_vps_flux_ssm.name
}

resource "aws_ssm_parameter" "public_vps_flux_access_key_id" {
  name             = local.public_vps_flux_access_key_id_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.public_vps_flux_ssm.id
  value_wo_version = 1
}

resource "aws_ssm_parameter" "public_vps_flux_secret_access_key" {
  name             = local.public_vps_flux_secret_access_key_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.public_vps_flux_ssm.secret
  value_wo_version = 1
}
