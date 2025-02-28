#####################################################################
# RDS Security Group Configuration
#####################################################################

resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  # Дозволяємо вхідний PostgreSQL трафік від ECS задач
  ingress {
    description     = "Allow PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  # Дозволяємо внутрішній PostgreSQL доступ
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
    description = "Allow internal PostgreSQL access"
  }

  # Дозволяємо весь вихідний трафік
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "rds-sg" })
}

#####################################################################
# RDS Subnet Group Configuration
#####################################################################

resource "aws_db_subnet_group" "this" {
  name       = "my-demo-db-subnet-group"
  subnet_ids = var.private_subnets
  tags       = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

#####################################################################
# RDS Instance Configuration
#####################################################################

resource "aws_db_instance" "this" {
  identifier = "my-demo-rds"
  
  # Базові налаштування бази даних
  engine         = "postgres"
  instance_class = "db.t3.micro"
  db_name        = var.db_name
  username       = var.db_username
  password       = var.db_password
  
  # Налаштування сховища
  allocated_storage = 20
  
  # Мережеві налаштування
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  # Налаштування резервного копіювання
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  
  # Налаштування оновлень
  auto_minor_version_upgrade = true
  skip_final_snapshot       = true
  
  # Моніторинг
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn

  tags = merge(var.common_tags, {
    Name        = "my-demo-rds"
    Backup      = "daily"
    Environment = "production"
  })
}

#####################################################################
# RDS Monitoring Role Configuration
#####################################################################

resource "aws_iam_role" "rds_monitoring_role" {
  name = "my-demo-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
