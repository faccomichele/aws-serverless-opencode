output "ecr_repository_url" {
  description = "URL of the ECR repository used by the task definition"
  value       = aws_ecr_repository.opencode.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.opencode.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.opencode.arn
}

output "scheduler_name" {
  description = "Name of the daily EventBridge Scheduler resource"
  value       = aws_scheduler_schedule.daily_opencode.name
}
