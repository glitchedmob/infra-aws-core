locals {
  dns_github_subject      = "repo:glitchedmob@9029666/infra-dns@1191350100"
  dns_github_main_subject = "${local.dns_github_subject}:ref:refs/heads/main"

  dns_ses_identity_arn = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/levizitting.com"
}

resource "aws_iam_role" "github_actions_dns" {
  name = "GitHubActionsInfraDNSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "${local.dns_github_subject}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    GitHubMainSubject    = local.dns_github_main_subject
    ManagedBy            = "OpenTofu"
    Repository           = "glitchedmob/infra-dns"
    TerraformStateKey    = "dns-global/terraform.tfstate"
    TerraformStatePrefix = "dns-global"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_dns_state" {
  role       = aws_iam_role.github_actions_dns.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy" "github_actions_dns" {
  name = "InfraDNSRepositoryAccess"
  role = aws_iam_role.github_actions_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSESIdentity"
        Effect = "Allow"
        Action = [
          "ses:GetEmailIdentity",
          "ses:ListTagsForResource",
        ]
        Resource = local.dns_ses_identity_arn
      },
    ]
  })
}
