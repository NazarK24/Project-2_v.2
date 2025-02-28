data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#############################
# ECS Cluster
#############################
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, { Name = var.ecs_cluster_name })
}

#############################
# Security Group for ECS tasks
#############################
resource "aws_security_group" "ecs_sg" {
  name        = "my-demo-ecs-cluster-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 8000
    to_port   = 8002
    protocol  = "tcp"
    self      = true
    description = "Allow internal service communication"
  }

  ingress {
    from_port       = 8000
    to_port         = 8002
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "Allow inbound traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "my-demo-ecs-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Окремі правила для RDS і Redis
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = var.rds_sg_id
  description             = "Allow outbound PostgreSQL to RDS"
}

resource "aws_security_group_rule" "ecs_to_redis" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = var.redis_sg_id
  description             = "Allow outbound Redis to ElastiCache"
}

resource "aws_security_group_rule" "ecs_to_endpoints" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg.id
  source_security_group_id = var.vpc_endpoints_sg_id
}

#############################
# ECS Task Definitions
#############################
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "frontend"
      image        = var.frontend_image_url
      cpu          = 256
      memory       = 512
      essential    = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "REDIS_HOST", value = var.redis_host },
        { name = "REDIS_PORT", value = "6379" },
        { name = "BACKEND_RDS_URL", value = "http://rds.my-demo.local:8001/test_connection/" },
        { name = "BACKEND_REDIS_URL", value = "http://redis.my-demo.local:8002/test_connection/" },
        { name = "DEBUG", value = "True" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/frontend"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "frontend"
          "awslogs-create-group"  = "true"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/ || exit 1"]
        interval    = 60
        timeout     = 30
        retries     = 3
        startPeriod = 180
      }
    }
  ])
}

resource "aws_ecs_task_definition" "backend_rds_task" {
  family                   = "backend-rds-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "backend-rds"
      image        = var.backend_rds_image_url
      cpu          = 1024
      memory       = 2048
      essential    = true
      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "DJANGO_SETTINGS_MODULE", value = "backend_rds.settings" },
        { name = "ALLOWED_HOSTS", value = "*" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/backend-rds"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "backend-rds"
          "awslogs-create-group"  = "true"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8001/test_connection/ || exit 1"]
        interval    = 30
        timeout     = 20
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture       = "X86_64"
  }

  tags = merge(var.common_tags, {
    Name = "backend-rds-task"
    Service = "backend-rds"
  })
}

resource "aws_ecs_task_definition" "backend_redis_task" {
  family                   = "backend-redis-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "backend-redis"
      image        = var.backend_redis_image_url
      cpu          = 1024
      memory       = 2048
      essential    = true
      portMappings = [
        {
          containerPort = 8002
          hostPort      = 8002
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "REDIS_HOST", value = var.redis_host },
        { name = "REDIS_PORT", value = "6379" },
        { name = "REDIS_DB", value = var.redis_db },
        { name = "DJANGO_SETTINGS_MODULE", value = "backend_redis.settings" },
        { name = "DEBUG", value = "True" },
        { name = "ALLOWED_HOSTS", value = "*" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/backend-redis"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "backend-redis"
          "awslogs-create-group"  = "true"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8002/test_connection/ || exit 1"]
        interval    = 30
        timeout     = 20
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture       = "X86_64"
  }

  tags = merge(var.common_tags, {
    Name = "backend-redis-task"
    Service = "backend-redis"
  })
}


#############################
# ECS Services
#############################
resource "aws_ecs_service" "frontend_service" {
  name                               = "frontend-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.frontend_task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 120
  force_delete                      = true
  enable_execute_command            = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 8000
  }
}

resource "aws_ecs_service" "backend_rds_service" {
  name                               = "backend-rds-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.backend_rds_task.arn
  desired_count                     = var.backend_rds_desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 120
  force_delete                      = true
  enable_execute_command            = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend_rds.arn
  }
}

resource "aws_ecs_service" "backend_redis_service" {
  name                               = "backend-redis-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.backend_redis_task.arn
  desired_count                     = var.backend_redis_desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 120
  force_delete                      = true
  enable_execute_command            = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend_redis.arn
  }
}

#############################
# IAM Role for CI/CD
#############################
resource "aws_iam_role" "cicd_role" {
  name = "cicd-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cicd_policy" {
  name = "cicd-ecs-policy"
  role = aws_iam_role.cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

#############################
# IAM Role for Fargate
#############################
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name = "ecs-execution-role-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:*",
          "elasticache:Connect",
          "elasticache:Describe*",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/frontend"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "backend_rds" {
  name              = "/ecs/backend-rds"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "backend_redis" {
  name              = "/ecs/backend-redis"
  retention_in_days = 14
  tags              = var.common_tags
}

# Моніторинг ECS кластера
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "ecs-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
}

# Моніторинг Frontend сервісу
resource "aws_cloudwatch_metric_alarm" "service_health" {
  alarm_name          = "frontend-service-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyTaskCount"
  namespace           = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = "1"
  alarm_description  = "This metric monitors frontend service health"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.frontend_service.name
  }
}

# Моніторинг Backend RDS сервісу
resource "aws_cloudwatch_metric_alarm" "backend_rds_health" {
  alarm_name          = "backend-rds-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyTaskCount"
  namespace           = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = "1"
  alarm_description  = "This metric monitors backend RDS service health"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.backend_rds_service.name
  }
}

# Моніторинг Backend Redis сервісу
resource "aws_cloudwatch_metric_alarm" "backend_redis_health" {
  alarm_name          = "backend-redis-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyTaskCount"
  namespace           = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = "1"
  alarm_description  = "This metric monitors backend Redis service health"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.backend_redis_service.name
  }
}

# Моніторинг пам'яті
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  alarm_name          = "ecs-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Memory utilization is too high"

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
  }
}

# Додати автоскейлінг для ECS сервісів
resource "aws_appautoscaling_target" "backend_rds" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.backend_rds_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags]
  }

  depends_on = [aws_ecs_service.backend_rds_service]
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-auto-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.backend_rds.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_rds.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-auto-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.backend_rds.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_rds.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# Моніторинг Frontend 5XX помилок
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "frontend-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "Too many 5XX errors in frontend service"

  dimensions = {
    TargetGroup = aws_ecs_service.frontend_service.name
  }
}

# Додаємо автоскейлінг для backend-redis
resource "aws_appautoscaling_target" "backend_redis" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.backend_redis_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags]
  }

  depends_on = [aws_ecs_service.backend_redis_service]
}

resource "aws_appautoscaling_policy" "redis_policy_cpu" {
  name               = "redis-cpu-auto-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.backend_redis.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_redis.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

resource "aws_appautoscaling_policy" "redis_policy_memory" {
  name               = "redis-memory-auto-scaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.backend_redis.resource_id
  scalable_dimension = aws_appautoscaling_target.backend_redis.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}