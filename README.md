# aws-serverless-opencode

A Terraform-based project to deploy Open Code AI Agent on AWS in a serverless-friendly approach.

## Docker image

Build the custom ARM64 image for ECR from repository root:

```bash
docker build -f docker/Dockerfile -t opencode-fargate:latest .
```

The image entrypoint (`docker/entrypoint.sh`) expects:

1. `config_selector` argument (for example `gemini`, `claude`, `copilot`), used to fetch `s3://$CONFIG_BUCKET/$CONFIG_PREFIX/<selector>.json`
2. `prompt_ssm_parameter` argument, the SSM parameter name containing the unattended prompt

At runtime, placeholders in the downloaded config are resolved automatically:

- `{{PARAM:parameter-name}}` -> AWS SSM Parameter Store value (with decryption)
- `{{SECRET:secret-id}}` -> AWS Secrets Manager value

The script exports:

- `OPENCODE_CONFIG_FILE` (resolved local config path)
- `OPENCODE_UNATTENDED_PROMPT` (prompt loaded from SSM)
- `OPENCODE_RESULTS_S3_URI` (when `RESULT_BUCKET` is set)
- `GH_TOKEN` / `GITHUB_TOKEN` (when `GH_PAT_SECRET_ID` is set; token is loaded from Secrets Manager and `gh auth login` is run automatically)

The image includes both AWS CLI and GitHub CLI (`gh`) for unattended ECS runs.

`MAX_TASK_DURATION_SECONDS` defaults to `3600` so the task cannot run longer than one hour.

## Terraform deployment

Terraform code is in `terraform/` and is split by concern:

- `ecr.tf`: ARM-compatible ECR repository and lifecycle policy
- `ecs.tf`: ECS cluster, task definition, CloudWatch logs
- `iam.tf`: least-privilege IAM roles for ECS task and EventBridge Scheduler
- `schedule.tf`: daily EventBridge Scheduler invoking ECS RunTask

### Quick start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

The task role includes read access to configuration/prompt data and write access to a separate result bucket prefix.
Use `ssm_parameter_path_prefix` and `secret_name_prefix` to scope runtime placeholder access, and set `gh_pat_secret_id` to auto-configure global `gh` authentication from AWS Secrets Manager.
