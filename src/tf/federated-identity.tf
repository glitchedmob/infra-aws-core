resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    ManagedBy = "OpenTofu"
  }
}

resource "aws_iam_openid_connect_provider" "public_edge" {
  url = "https://k8s-oidc-edge.levizitting.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    ManagedBy  = "OpenTofu"
    Repository = "glitchedmob/infra-public-edge"
  }
}

resource "aws_iam_policy" "public_edge_kubernetes_workload_boundary" {
  name        = "KubernetesWorkloadBoundary"
  path        = "/public-edge/"
  description = "Require public-edge workload roles to be used only by Kubernetes service accounts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowWorkloadPermissions"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid      = "DenyOtherFederatedProviders"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          ArnNotEquals = {
            "aws:FederatedProvider" = aws_iam_openid_connect_provider.public_edge.arn
          }
        }
      },
      {
        Sid      = "DenyNonServiceAccountSubjects"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotLike = {
            "k8s-oidc-edge.levizitting.com:sub" = "system:serviceaccount:*:*"
          }
        }
      },
      {
        Sid      = "DenyUnexpectedAudience"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "k8s-oidc-edge.levizitting.com:aud" = "sts.amazonaws.com"
          }
        }
      },
      {
        Sid    = "DenyPrivilegeEscalation"
        Effect = "Deny"
        Action = [
          "account:*",
          "iam:*",
          "identitystore:*",
          "organizations:*",
          "sso:*",
          "sso-directory:*",
          "sts:AssumeRole",
          "sts:AssumeRoleWithSAML",
          "sts:AssumeRoleWithWebIdentity",
          "sts:GetFederationToken",
          "sts:GetSessionToken",
        ]
        Resource = "*"
      },
    ]
  })
}
