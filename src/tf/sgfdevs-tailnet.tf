locals {
  sgfdevs_k3s_oidc_issuer     = "k8s-oidc.sgf.dev"
  sgfdevs_tailnet_subject     = "system:serviceaccount:kube-system:sgfdevs-tailnet-secrets"
  sgfdevs_ingress_authkey_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/homelab/headscale/pods/sgfdevs/ingress-gateway-auth-key"
}

resource "aws_iam_openid_connect_provider" "sgfdevs_k3s" {
  url = "https://${local.sgfdevs_k3s_oidc_issuer}"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    ManagedBy  = "OpenTofu"
    Repository = "glitchedmob/infra-aws-core"
  }
}

resource "aws_iam_role" "sgfdevs_tailnet_parameter_reader" {
  name        = "SGFDevsTailnetParameterReader"
  description = "Allow SGF Devs External Secrets to read its ingress Headscale auth key in LZ"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.sgfdevs_k3s.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.sgfdevs_k3s_oidc_issuer}:aud" = "sts.amazonaws.com"
            "${local.sgfdevs_k3s_oidc_issuer}:sub" = local.sgfdevs_tailnet_subject
          }
        }
      }
    ]
  })

  tags = {
    KubernetesNamespace      = "kube-system"
    KubernetesServiceAccount = "sgfdevs-tailnet-secrets"
    ManagedBy                = "OpenTofu"
    Repository               = "glitchedmob/infra-aws-core"
  }
}

resource "aws_iam_role_policy" "sgfdevs_tailnet_parameter_reader" {
  name = "ReadSGFDevsIngressAuthKey"
  role = aws_iam_role.sgfdevs_tailnet_parameter_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = local.sgfdevs_ingress_authkey_arn
      },
    ]
  })
}
