variable "sgfdevs_aws_account_id" {
  description = "Verified SGF Devs AWS account owning GitHubActionsInfraVMWorkloadsRole."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.sgfdevs_aws_account_id))
    error_message = "sgfdevs_aws_account_id must be the verified 12-digit SGF Devs AWS account ID."
  }
}

variable "aws_region" {
  description = "AWS region for state backend resources"
  type        = string
  default     = "us-east-2"
}
