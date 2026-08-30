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

locals {
  application_ses_senders = {
    levizitting_com = {
      domain      = local.ses_email_identity
      path        = "levizitting-com"
      policy_name = "LevizittingComSESSender"
    }
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
