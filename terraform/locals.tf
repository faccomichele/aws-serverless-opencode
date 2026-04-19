data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Project = "aws-serverless-opencode"
  })

  task_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.ecs_task[0].id]
}
