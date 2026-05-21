output "backend_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage."
  value       = aws_s3_bucket.tfstate_infra.bucket
}

output "backend_table_name" {
  description = "DynamoDB table name for state locking."
  value       = aws_dynamodb_table.tflock.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication."
  value       = aws_iam_role.github_actions_terraform.arn
  sensitive   = true
}

output "lz_vms_eso_access_key_id_ssm_path" {
  description = "SSM parameter path for the LZ VMs ESO IAM access key ID."
  value       = local.lz_vms_eso_access_key_id_path
}

output "lz_vms_eso_secret_access_key_ssm_path" {
  description = "SSM parameter path for the LZ VMs ESO IAM secret access key."
  value       = local.lz_vms_eso_secret_access_key_path
}
