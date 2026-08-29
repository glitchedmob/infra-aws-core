variable "aws_region" {
  description = "AWS region containing repository-managed resources."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  type        = string
}

variable "lz_k3s_oidc_provider_arn" {
  description = "ARN of the Kubernetes OIDC provider for the LZ K3s cluster."
  type        = string
}

variable "lz_k3s_workload_boundary_arn" {
  description = "Permissions boundary ARN for LZ K3s Kubernetes workload roles."
  type        = string
}

variable "public_edge_oidc_provider_arn" {
  description = "ARN of the Kubernetes OIDC provider for infra-public-edge."
  type        = string
}

variable "public_edge_workload_boundary_arn" {
  description = "Permissions boundary ARN for public-edge Kubernetes workload roles."
  type        = string
}

variable "state_bucket_arn" {
  description = "ARN of the shared OpenTofu state bucket."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the shared OpenTofu state bucket."
  type        = string
}

variable "state_lock_table_arn" {
  description = "ARN of the shared OpenTofu state lock table."
  type        = string
}
