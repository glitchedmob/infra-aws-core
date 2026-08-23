resource "aws_s3_bucket" "tfstate_infra" {
  bucket = "levizitting-infra-tf-state"

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_s3_bucket_versioning" "tfstate_infra" {
  bucket = aws_s3_bucket.tfstate_infra.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_infra" {
  bucket = aws_s3_bucket.tfstate_infra.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_infra" {
  bucket = aws_s3_bucket.tfstate_infra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate_infra" {
  bucket = aws_s3_bucket.tfstate_infra.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tflock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name = "GitHubActionsTerraformRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:glitchedmob@9029666/infra@1191379833:*",
              "repo:glitchedmob@9029666/infra-app-config@1189158374:*",
              "repo:glitchedmob@9029666/infra-dns@1191350100:*",
              "repo:glitchedmob@9029666/infra-public-edge@1189070796:*",
              "repo:glitchedmob@9029666/infra-vm-workloads@1191316259:*",
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "TerraformStateAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.tfstate_infra.arn,
          "${aws_s3_bucket.tfstate_infra.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.tflock.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_ssm" {
  name = "HomelabSSMParameterAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/homelab/*",
          "arn:aws:ssm:*:*:parameter/vm-workloads/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_ses" {
  name = "SESEmailIdentityReadPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:GetEmailIdentity",
          "ses:ListTagsForResource"
        ]
        Resource = aws_sesv2_email_identity.levizitting_com.arn
      }
    ]
  })
}

locals {
  application_ses_senders = {
    levizitting_com = {
      domain      = local.ses_email_identity
      path        = "levizitting-com"
      policy_name = "LevizittingComSESSender"
    }
  }
  application_ses_policy_arns = {
    for key, application in local.application_ses_senders :
    key => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/applications/${application.path}/${application.policy_name}"
  }
}

resource "aws_iam_policy" "application_ses_sender" {
  for_each = local.application_ses_senders

  name        = each.value.policy_name
  path        = "/applications/${each.value.path}/"
  description = "Allow ${each.value.domain} to send email from its tagged address"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          aws_sesv2_email_identity.levizitting_com.arn,
          aws_sesv2_configuration_set.transactional.arn,
        ]
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "$${aws:PrincipalTag/SESFromAddress}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_terraform_application_ses_iam" {
  name = "ApplicationSESCredentialAccessPolicy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [for key, application in local.application_ses_senders : {
        Sid      = "Create${replace(title(key), "_", "")}SESUsers"
        Effect   = "Allow"
        Action   = "iam:CreateUser"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/ManagedBy" = "OpenTofu"
          }
          StringLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
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
      }],
      [for key, application in local.application_ses_senders : {
        Sid    = "AttachOnly${replace(title(key), "_", "")}SESPolicy"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = local.application_ses_policy_arns[key]
          }
          StringEquals = {
            "iam:ResourceTag/ManagedBy" = "OpenTofu"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      }],
      [for key, application in local.application_ses_senders : {
        Sid    = "Manage${replace(title(key), "_", "")}SESUsers"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:DeleteUser",
          "iam:GetAccessKeyLastUsed",
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserTags",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:UpdateAccessKey"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          StringEquals = {
            "iam:ResourceTag/ManagedBy" = "OpenTofu"
          }
          StringLike = {
            "iam:ResourceTag/SESFromAddress" = "*@${application.domain}"
          }
          Null = {
            "iam:ResourceTag/Application" = "false"
          }
        }
      }],
      [for key, application in local.application_ses_senders : {
        Sid      = "RejectInvalid${replace(title(key), "_", "")}SenderTags"
        Effect   = "Deny"
        Action   = "iam:TagUser"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/applications/${application.path}/*"
        Condition = {
          Null = {
            "aws:RequestTag/SESFromAddress" = "false"
          }
          StringNotLike = {
            "aws:RequestTag/SESFromAddress" = "*@${application.domain}"
          }
        }
      }]
    )
  })
}
