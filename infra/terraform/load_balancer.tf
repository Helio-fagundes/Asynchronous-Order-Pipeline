#========================================================================
# Load Balancer
#========================================================================
resource "aws_lb" "alb" {
  name               = "alb-helio-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets = [
    aws_subnet.subnet_public_a.id,
    aws_subnet.subnet_public_b.id
  ]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  depends_on = [
    aws_security_group.elb_sg,
    aws_subnet.subnet_public_a,
    aws_subnet.subnet_public_b,
    aws_s3_bucket.lb_logs
  ]
}

resource "aws_lb_target_group" "tg_alb" {
  name        = "tg-alb-helio-terraform"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = 200
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.tg_alb.arn
    type             = "forward"
  }
}

#========================================================================
# Producer
#========================================================================

resource "aws_appautoscaling_target" "producer_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.producer_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "producer_cpu_policy" {
  name               = "producer-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.producer_target.resource_id
  scalable_dimension = aws_appautoscaling_target.producer_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.producer_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

#========================================================================
# Worker
#========================================================================

resource "aws_appautoscaling_target" "worker_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.worker_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_cpu_policy" {
  name               = "worker-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.worker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

#========================================================================
# ECS Cluster
#========================================================================

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster-helio-terraform"
}
