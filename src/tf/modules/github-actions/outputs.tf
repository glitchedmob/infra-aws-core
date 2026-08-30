output "app_config_role_arn" {
  description = "IAM role ARN for infra-app-config GitHub Actions."
  value       = aws_iam_role.github_actions_app_config.arn
}

output "dns_role_arn" {
  description = "IAM role ARN for infra-dns GitHub Actions."
  value       = aws_iam_role.github_actions_dns.arn
}

output "public_edge_role_arn" {
  description = "IAM role ARN for infra-public-edge GitHub Actions."
  value       = aws_iam_role.github_actions_public_edge.arn
}

output "vm_workloads_role_arn" {
  description = "IAM role ARN for infra-vm-workloads GitHub Actions."
  value       = aws_iam_role.github_actions_vm_workloads.arn
}
