locals {
  public_edge_github_subject      = "repo:glitchedmob@9029666/infra-public-edge@1189070796"
  public_edge_github_main_subject = "${local.public_edge_github_subject}:ref:refs/heads/main"

  public_edge_owned_ssm_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/x86-vps-node-01/*",
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/public-edge/*",
  ]
  public_edge_read_ssm_parameter_arns = concat(
    local.public_edge_owned_ssm_parameter_arns,
    [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/headscale/infra-public-edge/*",
    ]
  )
}

resource "aws_iam_role" "github_actions_public_edge" {
  name = "GitHubActionsInfraPublicEdgeRole"

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
            "token.actions.githubusercontent.com:sub" = "${local.public_edge_github_subject}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    GitHubMainSubject    = local.public_edge_github_main_subject
    ManagedBy            = "OpenTofu"
    Repository           = "glitchedmob/infra-public-edge"
    TerraformStateKey    = "public-edge/terraform.tfstate"
    TerraformStatePrefix = "public-edge"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_public_edge_state" {
  role       = aws_iam_role.github_actions_public_edge.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy" "github_actions_public_edge" {
  name = "InfraPublicEdgeRepositoryAccess"
  role = aws_iam_role.github_actions_public_edge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DescribeSSMParameters"
        Effect   = "Allow"
        Action   = "ssm:DescribeParameters"
        Resource = "*"
      },
      {
        Sid    = "ReadPublicEdgeSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParametersByPath",
          "ssm:ListTagsForResource",
        ]
        Resource = local.public_edge_read_ssm_parameter_arns
      },
      {
        Sid    = "ManagePublicEdgeSSMParametersFromMain"
        Effect = "Allow"
        Action = [
          "ssm:AddTagsToResource",
          "ssm:DeleteParameter",
          "ssm:PutParameter",
          "ssm:RemoveTagsFromResource",
        ]
        Resource = local.public_edge_owned_ssm_parameter_arns
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.public_edge_github_main_subject
          }
        }
      },
    ]
  })
}
