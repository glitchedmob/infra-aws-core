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

output "github_actions_app_config_role_arn" {
  description = "IAM role ARN for infra-app-config GitHub Actions."
  value       = module.github_actions.app_config_role_arn
  sensitive   = true
}

output "github_actions_dns_role_arn" {
  description = "IAM role ARN for infra-dns GitHub Actions."
  value       = module.github_actions.dns_role_arn
  sensitive   = true
}

output "github_actions_public_edge_role_arn" {
  description = "IAM role ARN for infra-public-edge GitHub Actions."
  value       = module.github_actions.public_edge_role_arn
  sensitive   = true
}

output "github_actions_vm_workloads_role_arn" {
  description = "IAM role ARN for infra-vm-workloads GitHub Actions."
  value       = module.github_actions.vm_workloads_role_arn
  sensitive   = true
}

output "lz_k3s_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the LZ K3s cluster."
  value       = aws_iam_openid_connect_provider.lz_k3s.arn
}

output "lz_k3s_workload_boundary_arn" {
  description = "Permissions boundary ARN for LZ K3s Kubernetes workload roles."
  value       = aws_iam_policy.lz_k3s_kubernetes_workload_boundary.arn
}

output "public_edge_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the public-edge Kubernetes cluster."
  value       = aws_iam_openid_connect_provider.public_edge.arn
}

output "public_edge_workload_boundary_arn" {
  description = "Permissions boundary ARN for public-edge Kubernetes workload roles."
  value       = aws_iam_policy.public_edge_kubernetes_workload_boundary.arn
}

output "ses_email_identity_arn" {
  description = "ARN of the SES identity used for outbound email."
  value       = aws_sesv2_email_identity.levizitting_com.arn
}

output "ses_mail_from_domain" {
  description = "Custom MAIL FROM domain used by SES."
  value       = aws_sesv2_email_identity_mail_from_attributes.levizitting_com.mail_from_domain
}
