# The source role name is owned by sgfdevs/infra-aws-core's github-actions module.
# Keep bootstrap role chaining separate from the Kubernetes OIDC reader.
resource "aws_iam_role" "sgfdevs_bootstrap_tailnet_parameter_reader" {
  name        = "SGFDevsBootstrapTailnetParameterReader"
  description = "Allow SGF Devs workflow bootstrap to read its ingress Headscale auth key in LZ"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.sgfdevs_aws_account_id}:role/GitHubActionsInfraVMWorkloadsRole"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = {
    ManagedBy  = "OpenTofu"
    Repository = "glitchedmob/infra-aws-core"
  }
}

resource "aws_iam_role_policy" "sgfdevs_bootstrap_tailnet_parameter_reader" {
  name = "ReadSGFDevsBootstrapIngressAuthKey"
  role = aws_iam_role.sgfdevs_bootstrap_tailnet_parameter_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = local.sgfdevs_ingress_authkey_arn
      },
    ]
  })
}
