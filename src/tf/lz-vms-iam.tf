locals {
  lz_vms_name                       = "lz-vms"
  lz_vms_iam_user_name              = "${local.lz_vms_name}-eso-ssm"
  lz_vms_eso_access_key_id_path     = "/homelab/${local.lz_vms_name}/eso-ssm-access-key-id"
  lz_vms_eso_secret_access_key_path = "/homelab/${local.lz_vms_name}/eso-ssm-secret-access-key"
}

data "aws_caller_identity" "lz_vms" {}

resource "aws_iam_user" "lz_vms_eso_ssm" {
  name = local.lz_vms_iam_user_name
}

resource "aws_iam_user_policy" "lz_vms_eso_ssm" {
  name = "${local.lz_vms_iam_user_name}-policy"
  user = aws_iam_user.lz_vms_eso_ssm.name

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
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.lz_vms.account_id}:parameter${local.lz_vms_eso_access_key_id_path}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.lz_vms.account_id}:parameter${local.lz_vms_eso_secret_access_key_path}"
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
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.lz_vms.account_id}:parameter/homelab/${local.lz_vms_name}/*",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.lz_vms.account_id}:parameter/vm-workloads/lz/infra-vm-workloads/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "lz_vms_eso_ssm" {
  user = aws_iam_user.lz_vms_eso_ssm.name
}

resource "aws_ssm_parameter" "lz_vms_eso_access_key_id" {
  name             = local.lz_vms_eso_access_key_id_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.lz_vms_eso_ssm.id
  value_wo_version = 1
}

resource "aws_ssm_parameter" "lz_vms_eso_secret_access_key" {
  name             = local.lz_vms_eso_secret_access_key_path
  type             = "SecureString"
  value_wo         = aws_iam_access_key.lz_vms_eso_ssm.secret
  value_wo_version = 1
}
