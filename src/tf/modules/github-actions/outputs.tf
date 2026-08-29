output "public_edge_role_arn" {
  description = "IAM role ARN for infra-public-edge GitHub Actions."
  value       = aws_iam_role.github_actions_public_edge.arn
}
