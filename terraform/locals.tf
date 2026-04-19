data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Project = "aws-serverless-opencode"
  })

  normalized_ssm_parameter_prefix = trimsuffix(trimprefix(var.ssm_parameter_path_prefix, "/"), "/")
  normalized_secret_prefix        = trimsuffix(trimprefix(var.secret_name_prefix, "/"), "/")

  ssm_parameter_arns = local.normalized_ssm_parameter_prefix != "" ? [
    "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.normalized_ssm_parameter_prefix}/*"
  ] : [
    "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
  ]

  secret_arns = concat(local.normalized_secret_prefix != "" ? [
    "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.normalized_secret_prefix}*"
  ] : [
    "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
  ],
    var.gh_pat_secret_id != "" ? ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.gh_pat_secret_id}*"] : []
  )

  task_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.ecs_task[0].id]
}
