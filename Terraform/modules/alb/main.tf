#####################################################################
# Application Load Balancer Configuration
#####################################################################

resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  # Налаштування видалення та відмовостійкості
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  # Налаштування логування
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(var.common_tags, { Name = "frontend-alb" })
}

#####################################################################
# ALB Logs S3 Bucket Configuration
#####################################################################

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "my-demo-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "alb-logs"
  })
}

# Політика доступу до S3 бакета
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.current.id}:root"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
      }
    ]
  })
}

# Налаштування власності об'єктів
resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Блокування публічного доступу
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Налаштування ACL
resource "aws_s3_bucket_acl" "alb_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.alb_logs]
  
  bucket = aws_s3_bucket.alb_logs.id
  acl    = "private"
}

# Налаштування версіонування
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

#####################################################################
# Target Group Configuration
#####################################################################

#####################################################################
# Backend API Target Groups
#####################################################################

# Target Group для RDS бекенд сервісу
resource "aws_lb_target_group" "backend_rds" {
  name        = "backend-rds-tg-${formatdate("YYYYMMDDHHmm", timestamp())}"
  port        = var.backend_rds_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  # Налаштування перевірки здоров'я
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302,401,403"
    path                = "/test_connection/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 15
    unhealthy_threshold = 5
  }
  
  tags = merge(var.common_tags, {
    Name        = "backend-rds-tg"
    Environment = var.environment
    Project     = var.project_name
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Target Group для Redis бекенд сервісу
resource "aws_lb_target_group" "backend_redis" {
  name        = "backend-redis-tg-${formatdate("YYYYMMDDHHmm", timestamp())}"
  port        = var.backend_redis_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  # Налаштування перевірки здоров'я
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302,401,403"
    path                = "/test_connection/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 15
    unhealthy_threshold = 5
  }
  
  tags = merge(var.common_tags, {
    Name        = "backend-redis-tg"
    Environment = var.environment
    Project     = var.project_name
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

#####################################################################
# Listener Configuration
#####################################################################

# Listener для RDS бекенду (порт 8001)
resource "aws_lb_listener" "backend_rds_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 8001
  protocol          = "HTTP"
  
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"Resource not found\"}"
      status_code  = "404"
    }
  }
  
  tags = merge(var.common_tags, {
    Name = "rds-listener"
  })
}

# Listener для Redis бекенду (порт 8002)
resource "aws_lb_listener" "backend_redis_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 8002
  protocol          = "HTTP"
  
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"Resource not found\"}"
      status_code  = "404"
    }
  }
  
  tags = merge(var.common_tags, {
    Name = "redis-listener"
  })
}

#####################################################################
# Listener Rules Configuration
#####################################################################

# Правило для обробки OPTIONS запитів для CORS на рівні ALB
resource "aws_lb_listener_rule" "backend_rds_options_rule" {
  listener_arn = aws_lb_listener.backend_rds_listener.arn
  priority     = 5

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\": \"CORS preflight response\"}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/test_connection", "/test_connection/", "/test_connection/*"]
    }
  }

  condition {
    http_request_method {
      values = ["OPTIONS"]
    }
  }
}

# Правило для обробки OPTIONS запитів для CORS на рівні ALB - Redis
resource "aws_lb_listener_rule" "backend_redis_options_rule" {
  listener_arn = aws_lb_listener.backend_redis_listener.arn
  priority     = 5

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\": \"CORS preflight response\"}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/test_connection", "/test_connection/", "/test_connection/*"]
    }
  }

  condition {
    http_request_method {
      values = ["OPTIONS"]
    }
  }
}

# Правило для шляху /test_connection (без слешу в кінці) для RDS
resource "aws_lb_listener_rule" "backend_rds_rule_root" {
  listener_arn = aws_lb_listener.backend_rds_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_rds.arn
  }

  condition {
    path_pattern {
      values = ["/test_connection"]
    }
  }
}

# Правило для шляху /test_connection (без слешу в кінці) для Redis
resource "aws_lb_listener_rule" "backend_redis_rule_root" {
  listener_arn = aws_lb_listener.backend_redis_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_redis.arn
  }

  condition {
    path_pattern {
      values = ["/test_connection"]
    }
  }
}

# Правило для шляху /test_connection/ (з слешом) та підшляхів для RDS
resource "aws_lb_listener_rule" "backend_rds_rule" {
  listener_arn = aws_lb_listener.backend_rds_listener.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_rds.arn
  }

  condition {
    path_pattern {
      values = ["/test_connection/", "/test_connection/*"]
    }
  }
}

# Правило для шляху /test_connection/ (з слешом) та підшляхів для Redis
resource "aws_lb_listener_rule" "backend_redis_rule" {
  listener_arn = aws_lb_listener.backend_redis_listener.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_redis.arn
  }

  condition {
    path_pattern {
      values = ["/test_connection/", "/test_connection/*"]
    }
  }
}

#####################################################################
# Security Group Configuration
#####################################################################

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  
  # Дозволяємо вхідний трафік на порт 8001 (RDS бекенд)
  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow RDS backend traffic"
  }
  
  # Дозволяємо вхідний трафік на порт 8002 (Redis бекенд)
  ingress {
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Redis backend traffic"
  }

  # Дозволяємо весь вихідний трафік
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name = "alb-sg"
  })
}

#####################################################################
# CloudWatch Alarms Configuration
#####################################################################

resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  alarm_name          = "target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  
  dimensions = {
    LoadBalancer = aws_lb.frontend_alb.arn_suffix
  }
}

#####################################################################
# Data Sources
#####################################################################

data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Код AWS WAF і Lambda функцій був повністю видалений

