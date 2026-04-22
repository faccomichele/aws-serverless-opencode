variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix used for created resources"
  type        = string
  default     = "opencode-job"
}

variable "vpc_id" {
  description = "VPC ID where scheduled ECS tasks run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by scheduled ECS tasks"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Optional existing security group IDs for ECS tasks"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP to task ENI"
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "ECR image tag to run"
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 2048
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "config_bucket" {
  description = "S3 bucket containing opencode configuration files"
  type        = string
}

variable "config_prefix" {
  description = "S3 key prefix containing config files"
  type        = string
  default     = "configs"
}

variable "result_bucket" {
  description = "S3 bucket where execution results are uploaded"
  type        = string
}

variable "result_prefix" {
  description = "S3 key prefix used for uploaded execution results"
  type        = string
  default     = "results"
}

variable "gh_pat_secret_id" {
  description = "Optional Secrets Manager secret ID containing GitHub PAT used by gh CLI"
  type        = string
  default     = ""
}

variable "ssm_parameter_path_prefix" {
  description = "SSM parameter path prefix allowed for runtime placeholder resolution"
  type        = string
  default     = "/opencode/"
}

variable "secret_name_prefix" {
  description = "Secrets Manager secret name prefix allowed for runtime placeholder resolution"
  type        = string
  default     = "opencode/"
}

variable "prompt_parameter_name" {
  description = "Default SSM parameter containing unattended prompt text"
  type        = string
  default     = "/opencode/prompts/default"
}

variable "max_task_duration_seconds" {
  description = "Maximum task execution duration enforced by container entrypoint"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_task_duration_seconds > 0 && var.max_task_duration_seconds <= 3600
    error_message = "max_task_duration_seconds must be between 1 and 3600 seconds."
  }
}

variable "schedule_expression" {
  description = "EventBridge Scheduler expression"
  type        = string
  default     = "rate(1 day)"
}

variable "schedule_enabled" {
  description = "Whether the daily schedule is enabled"
  type        = bool
  default     = true
}

variable "schedule_max_event_age_seconds" {
  description = "Maximum EventBridge Scheduler event age for retries/dispatch"
  type        = number
  default     = 3600
}

variable "schedule_max_retry_attempts" {
  description = "Maximum EventBridge Scheduler retries for failed invocations"
  type        = number
  default     = 0
}

variable "schedule_arguments" {
  description = "Example daily arguments passed to the container entrypoint"
  type        = list(string)
  default     = ["gemini", "/opencode/prompts/default", "opencode"]
}

variable "kms_key_arns" {
  description = "Optional KMS keys allowed for decrypting SSM parameters and secrets"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
