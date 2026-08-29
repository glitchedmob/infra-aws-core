locals {
  vm_workloads_github_subject      = "repo:glitchedmob@9029666/infra-vm-workloads@1191316259"
  vm_workloads_github_main_subject = "${local.vm_workloads_github_subject}:ref:refs/heads/main"

  vm_workloads_owned_ssm_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/lz/infra-vm-workloads/*",
  ]
  vm_workloads_operational_ssm_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/headscale/lz-k3s/*",
  ]

  vm_workloads_workload_role_arn_pattern = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lz-k3s/*"
}

resource "aws_iam_role" "github_actions_vm_workloads" {
  name = "GitHubActionsInfraVMWorkloadsRole"

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
            "token.actions.githubusercontent.com:sub" = "${local.vm_workloads_github_subject}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    GitHubMainSubject    = local.vm_workloads_github_main_subject
    ManagedBy            = "OpenTofu"
    Repository           = "glitchedmob/infra-vm-workloads"
    TerraformStateKey    = "vm-workloads/terraform.tfstate"
    TerraformStatePrefix = "vm-workloads"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_vm_workloads_state" {
  role       = aws_iam_role.github_actions_vm_workloads.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy" "github_actions_vm_workloads" {
  name = "InfraVMWorkloadsRepositoryAccess"
  role = aws_iam_role.github_actions_vm_workloads.id

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
        Sid    = "ReadVMWorkloadsSSMParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:ListTagsForResource",
        ]
        Resource = local.vm_workloads_owned_ssm_parameter_arns
      },
      {
        Sid    = "ReadVMWorkloadsOperationalSSMParametersFromMain"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:ListTagsForResource",
        ]
        Resource = local.vm_workloads_operational_ssm_parameter_arns
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.vm_workloads_github_main_subject
          }
        }
      },
      {
        Sid    = "ReadLZK3sOIDCProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
        ]
        Resource = var.lz_k3s_oidc_provider_arn
      },
      {
        Sid    = "ReadLZK3sWorkloadRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
      },
      {
        Sid    = "ManageVMWorkloadsSSMParametersFromMain"
        Effect = "Allow"
        Action = [
          "ssm:AddTagsToResource",
          "ssm:DeleteParameter",
          "ssm:PutParameter",
          "ssm:RemoveTagsFromResource",
        ]
        Resource = local.vm_workloads_owned_ssm_parameter_arns
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.vm_workloads_github_main_subject
          }
        }
      },
      {
        Sid      = "CreateLZK3sWorkloadRoleFromMain"
        Effect   = "Allow"
        Action   = "iam:CreateRole"
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary"                 = var.lz_k3s_workload_boundary_arn
            "token.actions.githubusercontent.com:sub" = local.vm_workloads_github_main_subject
          }
        }
      },
      {
        Sid    = "ManageLZK3sWorkloadRoleTagsFromMain"
        Effect = "Allow"
        Action = [
          "iam:TagRole",
          "iam:UntagRole",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "KubernetesNamespace",
              "KubernetesServiceAccount",
              "ManagedBy",
              "Repository",
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = local.vm_workloads_github_main_subject
          }
          StringEqualsIfExists = {
            "aws:RequestTag/ManagedBy"  = "OpenTofu"
            "aws:RequestTag/Repository" = "glitchedmob/infra-vm-workloads"
          }
        }
      },
      {
        Sid    = "ManageBoundedLZK3sWorkloadRoleFromMain"
        Effect = "Allow"
        Action = [
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:PutRolePermissionsBoundary",
          "iam:PutRolePolicy",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
        ]
        Resource = local.vm_workloads_workload_role_arn_pattern
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary"                 = var.lz_k3s_workload_boundary_arn
            "token.actions.githubusercontent.com:sub" = local.vm_workloads_github_main_subject
          }
        }
      },
    ]
  })
}
