# IAC — Sample Terraform repo (Pattern 2 layout)

**Not part of the Skill deliverable.** Pure Terraform code — two root modules wired by `terraform_remote_state` — used as sample input for the Skill's extract phase or as a real deployment target.

Test fixtures for offline Skill testing (env-model JSONs + synthetic state files) live one level up at `../fixtures/`, not in here.

## Structure (Pattern 2 — root per layer + named workspaces per env)

```
IAC/
├── network/           # Root #1: VPC, subnets, IGW, NAT, EIP, route tables
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── backend.tf      # S3 backend, key = "network/terraform.tfstate"
│   └── envs/
│       ├── dev.tfvars
│       └── prod.tfvars
└── application/       # Root #2: 2 EC2 nginx + SGs + ALB + 3 S3 + RDS + 2 Lambda
    ├── main.tf         # Reads network outputs via terraform_remote_state
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── backend.tf      # S3 backend, key = "application/terraform.tfstate"
    ├── envs/{dev,prod}.tfvars
    └── lambda/hello.py
```

## State file layout

Each root has its own S3 key. Named workspaces (`dev`, `prod`) separate envs.

| Root | Workspace | S3 state key (effective) |
|---|---|---|
| `network` | `dev` | `s3://tf-poc-state-805863115079-ap-south-1/env:/dev/network/terraform.tfstate` |
| `network` | `prod` | `s3://tf-poc-state-805863115079-ap-south-1/env:/prod/network/terraform.tfstate` |
| `application` | `dev` | `s3://tf-poc-state-805863115079-ap-south-1/env:/dev/application/terraform.tfstate` |
| `application` | `prod` | `s3://tf-poc-state-805863115079-ap-south-1/env:/prod/application/terraform.tfstate` |

The application root reads the network root's outputs (`vpc_id`, subnets) via a `terraform_remote_state` data source pointing at the same workspace's network state — so cross-state references work automatically.

## Apply order

```bash
export AWS_PROFILE=test21
cd network
terraform init
terraform workspace select dev   # (or terraform workspace new dev)
terraform apply -var-file=envs/dev.tfvars

cd ../application
terraform init
terraform workspace select dev
terraform apply -var-file=envs/dev.tfvars
```

Per Ganesh: **don't worry about apply succeeding** — partial states are still useful for the Skill renderer. (Lambda will fail without a `hello.zip`; AMI lookup is region-aware via SSM parameter.)

## Cleanup

```bash
cd application && AWS_PROFILE=test21 terraform destroy -var-file=envs/dev.tfvars
cd ../network && AWS_PROFILE=test21 terraform destroy -var-file=envs/dev.tfvars
```

Order matters — destroy application first, then network (so the `terraform_remote_state` reference is still valid).

