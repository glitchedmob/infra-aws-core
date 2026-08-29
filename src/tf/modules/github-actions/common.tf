data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "terraform_state_access" {
  name        = "GitHubActionsTerraformStateAccess"
  description = "Repository-scoped OpenTofu state access derived from IAM role tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadStateBucketMetadata"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
        ]
        Resource = var.state_bucket_arn
      },
      {
        Sid      = "ListRepositoryState"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = var.state_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "$${aws:PrincipalTag/TerraformStatePrefix}",
              "$${aws:PrincipalTag/TerraformStatePrefix}/*",
            ]
          }
        }
      },
      {
        Sid      = "ReadRepositoryState"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.state_bucket_arn}/$${aws:PrincipalTag/TerraformStateKey}"
      },
      {
        Sid      = "DescribeStateLockTable"
        Effect   = "Allow"
        Action   = "dynamodb:DescribeTable"
        Resource = var.state_lock_table_arn
      },
      {
        Sid    = "ManageRepositoryStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Resource = var.state_lock_table_arn
        Condition = {
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = "${var.state_bucket_name}/$${aws:PrincipalTag/TerraformStateKey}*"
          }
        }
      },
      {
        Sid      = "WriteRepositoryStateFromMain"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${var.state_bucket_arn}/$${aws:PrincipalTag/TerraformStateKey}"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "$${aws:PrincipalTag/GitHubMainSubject}"
          }
        }
      },
    ]
  })
}
