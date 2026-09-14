resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/producer-task"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/worker-task"
  retention_in_days = 7
}