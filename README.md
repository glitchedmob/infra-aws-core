# AWS Core Infrastructure

Terraform configuration for AWS bootstrap resources. This is a **local-only** stack - all applies must be run from a local workstation, not via CI/CD.

## Scope

- **OpenTofu (`src/tf/`)**: provisions foundational AWS backend resources used by other stacks.

The stack includes:

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
make help
make tf-init
make tf-plan
make tf-show ARGS=tfplan
make tf-output
make tf-apply
make tf-validate
make tf-format
make tf-lint-fix
```

## CI Checks

On pull requests, CI will automatically run:
- `tofu validate` - Syntax validation
- `tofu fmt -check` - Format checking

No deployments occur via CI; this is validation-only.

## Outputs

| Output | Description |
|--------|-------------|
| `backend_bucket_name` | S3 bucket for Terraform state |
| `backend_table_name` | DynamoDB table for state locking |
| `github_actions_role_arn` | IAM role ARN for GitHub Actions (sensitive) |

## Operational Notes

- **Bootstrap Order**: This must be applied first before any other infrastructure stacks can use remote state
- **Local-Only**: No automatic deployments via GitHub Actions
- **State Storage**: This stack uses the shared S3 backend with DynamoDB locking (`aws-global/terraform.tfstate`).
