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

resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg-${formatdate("YYYYMMDDHHmm", timestamp())}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Налаштування перевірки здоров'я
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "frontend-tg"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

#####################################################################
# Listener Configuration
#####################################################################

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

#####################################################################
# Security Group Configuration
#####################################################################

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  # Дозволяємо вхідний HTTP трафік
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо весь вихідний трафік
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "alb-sg"
    Purpose = "ALB security"
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

