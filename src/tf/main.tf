resource "aws_s3_bucket" "tfstate_infra" {
  bucket = "levizitting-infra-tf-state"

  tags = {
    ManagedBy = "terraform"
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
    ManagedBy = "terraform"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    ManagedBy = "terraform"
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
              "repo:glitchedmob/infra:*",
              "repo:glitchedmob/infra-headscale:*",
              "repo:glitchedmob/infra-public-edge:*",
              "repo:glitchedmob/infra-vm-workloads:*",
              "repo:glitchedmob/infra-dns:*",
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
    ManagedBy = "terraform"
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
