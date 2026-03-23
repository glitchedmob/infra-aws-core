# AWS Core Infrastructure

Terraform configuration for AWS bootstrap resources. This is a **local-only** stack - all applies must be run from a local workstation, not via CI/CD.

## Purpose

Creates foundational AWS infrastructure required by all other infrastructure stacks:

- **S3 Bucket** (`levizitting-infra-tf-state`) - Remote state storage with versioning and encryption
- **DynamoDB Table** (`terraform-locks`) - State locking to prevent concurrent modifications
- **OIDC Provider** - GitHub Actions OIDC trust for AWS authentication
- **IAM Role** (`GitHubActionsTerraformRole`) - Allows GitHub Actions workflows to manage state and SSM parameters

## Usage

### Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.11 (version specified in `src/tf/.tofu-version`)
- AWS credentials configured locally (via AWS CLI, environment variables, or IAM role)

### Local Operations

```bash
# See all available commands
make help

# Initialize (run once)
make tf-init

# Preview changes
make tf-plan

# Apply changes
make tf-apply

# Validate syntax
make tf-validate

# Check formatting
make tf-format
```

### CI Checks

On pull requests, CI will automatically run:
- `tofu validate` - Syntax validation
- `tofu fmt -check` - Format checking

No deployments occur via CI - this is strictly for validation.

## Outputs

| Output | Description |
|--------|-------------|
| `backend_bucket_name` | S3 bucket for Terraform state |
| `backend_table_name` | DynamoDB table for state locking |
| `github_actions_role_arn` | IAM role ARN for GitHub Actions (sensitive) |

## Important Notes

- **Bootstrap Order**: This must be applied first before any other infrastructure stacks can use remote state
- **Local-Only**: No automatic deployments via GitHub Actions
- **State Storage**: This stack uses local state (not stored in S3) since it creates the S3 backend used by other stacks
