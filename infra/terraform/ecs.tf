#========================================================================
# Producer
#========================================================================

resource "aws_ecs_task_definition" "task_def_producer" {
  family                   = "producer-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer-container"
      image     = "public.ecr.aws/nginx/nginx:alpine"
      environment = [
        {
          name  = "SQS_URL"
          value = aws_sqs_queue.fila_pedidos.id
        },
        {
          name  = "DYNAMODB_TABLE"
          value = aws_dynamodb_table.requisicoes.name
        },
        {
          name  = "TOPIC_ARN"
          value = aws_sns_topic.notificacao_pipeline.arn
        }
      ]
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "producer_service" {
  name            = "producer-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_def_producer.arn
  desired_count = 2
  launch_type = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_alb.arn
    container_name   = "producer-container"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.listener,
    aws_lb_target_group.tg_alb
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}


#========================================================================
# Worker
#========================================================================

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "worker-api"
    image     = "public.ecr.aws/nginx/nginx:alpine"
    essential = true
    portMappings = [
      {
        containerPort = 8081
        hostPort = 8081
      }]
  }])
}

resource "aws_ecs_service" "worker_service" {
  name            = "worker-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_lb_listener.listener,
    aws_lb_target_group.tg_alb
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}
