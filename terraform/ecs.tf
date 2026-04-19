resource "aws_security_group" "ecs_task" {
  count = length(var.security_group_ids) == 0 ? 1 : 0

  name        = "${var.name_prefix}-ecs-task"
  description = "Security group for opencode scheduled task"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster" "opencode" {
  name = "${var.name_prefix}-cluster"
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "opencode" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "opencode" {
  family                   = "${var.name_prefix}-task"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "opencode"
      image     = "${aws_ecr_repository.opencode.repository_url}:${var.image_tag}"
      essential = true
      command   = var.schedule_arguments
      environment = [
        {
          name  = "CONFIG_BUCKET"
          value = var.config_bucket
        },
        {
          name  = "CONFIG_PREFIX"
          value = var.config_prefix
        },
        {
          name  = "RESULT_BUCKET"
          value = var.result_bucket
        },
        {
          name  = "RESULT_PREFIX"
          value = var.result_prefix
        },
        {
          name  = "MAX_TASK_DURATION_SECONDS"
          value = tostring(var.max_task_duration_seconds)
        },
        {
          name  = "GH_PAT_SECRET_ID"
          value = var.gh_pat_secret_id
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.opencode.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}
