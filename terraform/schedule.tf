resource "aws_scheduler_schedule_group" "opencode" {
  name = "${var.name_prefix}-schedules"
  tags = local.common_tags
}

resource "aws_scheduler_schedule" "daily_opencode" {
  name       = "${var.name_prefix}-daily"
  group_name = aws_scheduler_schedule_group.opencode.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "UTC"
  state                        = var.schedule_enabled ? "ENABLED" : "DISABLED"

  target {
    arn      = aws_ecs_cluster.opencode.arn
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.opencode.arn
      launch_type         = "FARGATE"
      task_count          = 1
      platform_version    = "LATEST"

      network_configuration {
        subnets          = var.subnet_ids
        security_groups  = local.task_security_group_ids
        assign_public_ip = var.assign_public_ip
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 0
    }
  }

  tags = local.common_tags
}
