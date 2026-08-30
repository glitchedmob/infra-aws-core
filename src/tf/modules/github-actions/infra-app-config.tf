locals {
  app_config_github_subject      = "repo:glitchedmob@9029666/infra-app-config@1189158374"
  app_config_github_main_subject = "${local.app_config_github_subject}:ref:refs/heads/main"

  app_config_owned_ssm_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/headscale/*",
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/monitor/proxmox/*",
  ]
  app_config_read_ssm_parameter_arns = concat(
    local.app_config_owned_ssm_parameter_arns,
    [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/lz/infra-vm-workloads/dex-openbao-client-secret",
    ]
  )

  app_config_ses_policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/applications/levizitting-com/LevizittingComSESSender"
  app_config_ses_user_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/levizitting-com/sparky-ses-smtp",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/levizitting-com/zitadel-ses-smtp",
  ]
}

resource "aws_iam_role" "github_actions_app_config" {
  name = "GitHubActionsInfraAppConfigRole"

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
            "token.actions.githubusercontent.com:sub" = "${local.app_config_github_subject}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    GitHubMainSubject    = local.app_config_github_main_subject
    ManagedBy            = "OpenTofu"
    Repository           = "glitchedmob/infra-app-config"
    TerraformStateKey    = "app-config/terraform.tfstate"
    TerraformStatePrefix = "app-config"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_app_config_state" {
  role       = aws_iam_role.github_actions_app_config.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy" "github_actions_app_config" {
  name = "InfraAppConfigRepositoryAccess"
  role = aws_iam_role.github_actions_app_config.id

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
        Sid    = "ReadAppConfigSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:ListTagsForResource",
        ]
        Resource = local.app_config_read_ssm_parameter_arns
      },
      {
        Sid    = "ReadApplicationSESUsers"
        Effect = "Allow"
        Action = [
          "iam:GetAccessKeyLastUsed",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedUserPolicies",
          "iam:ListGroupsForUser",
          "iam:ListUserTags",
        ]
        Resource = local.app_config_ses_user_arns
      },
      {
        Sid    = "ManageAppConfigSSMParametersFromMain"
        Effect = "Allow"
        Action = [
          "ssm:AddTagsToResource",
          "ssm:DeleteParameter",
          "ssm:PutParameter",
          "ssm:RemoveTagsFromResource",
        ]
        Resource = local.app_config_owned_ssm_parameter_arns
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.app_config_github_main_subject
          }
        }
      },
      {
        Sid      = "CreateApplicationSESUsersFromMain"
        Effect   = "Allow"
        Action   = "iam:CreateUser"
        Resource = local.app_config_ses_user_arns
        Condition = {
          StringEquals = {
            "aws:RequestTag/ManagedBy"                = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = local.app_config_github_main_subject
          }
          StringLike = {
            "aws:RequestTag/SESFromAddress" = "*@levizitting.com"
          }
          Null = {
            "aws:RequestTag/Application" = "false"
          }
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "Application",
              "Environment",
              "ManagedBy",
              "SESFromAddress",
            ]
          }
        }
      },
      {
        Sid    = "ManageApplicationSESUserTagsFromMain"
        Effect = "Allow"
        Action = [
          "iam:TagUser",
          "iam:UntagUser",
        ]
        Resource = local.app_config_ses_user_arns
        Condition = {
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "Application",
              "Environment",
              "ManagedBy",
              "SESFromAddress",
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.app_config_github_main_subject
          }
          StringEqualsIfExists = {
            "aws:RequestTag/ManagedBy" = "OpenTofu"
          }
          StringLikeIfExists = {
            "aws:RequestTag/SESFromAddress" = "*@levizitting.com"
          }
        }
      },
      {
        Sid    = "AttachApplicationSESPolicyFromMain"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
        ]
        Resource = local.app_config_ses_user_arns
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = local.app_config_ses_policy_arn
          }
          StringEquals = {
            "iam:ResourceTag/ManagedBy"               = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = local.app_config_github_main_subject
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@levizitting.com"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      },
      {
        Sid    = "ManageApplicationSESUsersFromMain"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:DeleteUser",
          "iam:UpdateAccessKey",
        ]
        Resource = local.app_config_ses_user_arns
        Condition = {
          StringEquals = {
            "iam:ResourceTag/ManagedBy"               = "OpenTofu"
            "token.actions.githubusercontent.com:sub" = local.app_config_github_main_subject
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@levizitting.com"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      },
      {
        Sid      = "RejectInvalidApplicationSESSenderTags"
        Effect   = "Deny"
        Action   = "iam:TagUser"
        Resource = local.app_config_ses_user_arns
        Condition = {
          Null = {
            "aws:RequestTag/SESFromAddress" = "false"
          }
          StringNotLike = {
            "aws:RequestTag/SESFromAddress" = "*@levizitting.com"
          }
        }
      },
    ]
  })
}
