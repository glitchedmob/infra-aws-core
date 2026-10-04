# infra-aws-core

Provisions LZ shared AWS foundation resources, including remote state backend, CI access roles, and account access baseline.

## Scope
- Owns: S3 + DynamoDB backend resources used by OpenTofu/Terraform state.
- Owns: GitHub Actions OIDC trust and IAM role/policies for infrastructure automation.
- Owns: AWS IAM Identity Center groups, permission sets, and account assignments.

## Structure
- `src/tf/`: OpenTofu resources for backend, IAM/OIDC, and Identity Center.
- `.github/workflows/`: Validation workflow for Terraform/OpenTofu changes.

## Run
```bash
make help
make tf-init
make tf-plan
make tf-apply
make tf-output
```

## Workflow bootstrap Headscale access

The existing LZ `GitHubActionsInfraVMWorkloadsRole` can read exactly these
Headscale parameters with `ssm:GetParameter` from a GitHub OIDC session on main:

- `/homelab/headscale/pods/lz/ingress-gateway-auth-key`
- `/homelab/headscale/pods/lz/dns-gateway-auth-key`

Its existing GitHub trust and workload parameter permissions are unchanged.

`SGFDevsBootstrapTailnetParameterReader` is a separate role in the LZ account.
It trusts only
`arn:aws:iam::<SGFDEVS_ACCOUNT_ID>:role/GitHubActionsInfraVMWorkloadsRole`
for `sts:AssumeRole`. Its sole permission is `ssm:GetParameter` on
`/homelab/headscale/pods/sgfdevs/ingress-gateway-auth-key`. SGF AWS core
limits the source role's new assume-role permission to its main GitHub OIDC
subject. The existing `SGFDevsTailnetParameterReader` Kubernetes OIDC role
and trust are unchanged.

Set the required `TF_VAR_sgfdevs_aws_account_id` to the verified SGF Devs
account owning that source role. The role name comes from
[SGF AWS core's GitHub Actions module](https://github.com/sgfdevs/infra-aws-core/blob/f93fea0/src/tf/modules/github-actions/common.tf).
Local resource ARNs use the existing `aws_caller_identity.current.account_id`.
No remote state or cross-account IAM lookup is needed. This repository does
not publish numeric account IDs. Verify the account input against the existing
SGF workflow role configuration before using it, not a placeholder.

The parameter owner,
[LZ app-config's Headscale module](https://github.com/glitchedmob/infra-app-config/blob/34bb24f88d2b75586caf40f81b866f8f7ac303dd/src/tf/modules/headscale/modules/pre-auth-key/main.tf),
creates `SecureString` parameters without `key_id`, using the default SSM
encryption key. The cross-account bootstrap reader runs in the parameter-owning
LZ account. No customer-managed KMS key permission is added. If that encryption
contract changes, review narrow decrypt permissions and the key policy separately.

Use the existing manual Ansible workflow on main with
`initialize-terraform=true`. Its reusable workflow only configures AWS
credentials when that input is true. The new main-only permissions match the
checked-in repository-ID-qualified GitHub subjects. AWS documents OIDC `sub`
as [available in the original role session](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-wif).
No branch condition is added to the chained reader's SSM permission, which
must not depend on retaining the source OIDC context.

The controller should assume the bootstrap reader only when the SGF tailnet
Secret is missing, then use its short-lived credentials for that single
decrypted SSM lookup. Do not persist the credentials or use the runtime reader
to bootstrap. Role chaining permits at most a one-hour session. A complete
existing Secret needs neither this assumption nor a parameter read.

## Operating constraints
- Apply this repo before dependent stacks that use the shared backend and IAM role outputs.
- Applies are manual/local; CI runs validation only.
