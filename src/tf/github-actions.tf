module "github_actions" {
  source = "./modules/github-actions"

  aws_region                        = var.aws_region
  oidc_provider_arn                 = aws_iam_openid_connect_provider.github_actions.arn
  public_edge_oidc_provider_arn     = aws_iam_openid_connect_provider.public_edge.arn
  public_edge_workload_boundary_arn = aws_iam_policy.public_edge_kubernetes_workload_boundary.arn
  state_bucket_arn                  = aws_s3_bucket.tfstate_infra.arn
  state_bucket_name                 = aws_s3_bucket.tfstate_infra.bucket
  state_lock_table_arn              = aws_dynamodb_table.tflock.arn
}
