#####################################################################
# Redis Security Group Configuration
#####################################################################

resource "aws_security_group" "redis_sg" {
  name_prefix = "redis-sg-"
  vpc_id      = var.vpc_id

  # Дозволяємо вхідний трафік від ECS задач
  ingress {
    description     = "Allow Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
  }

  # Дозволяємо весь вихідний трафік
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name    = "redis-sg"
    Service = "redis"
  })
}

#####################################################################
# Redis Subnet Group Configuration
#####################################################################

resource "aws_elasticache_subnet_group" "this" {
  name       = "my-demo-redis-subnet-group"
  subnet_ids = var.private_subnets
  
  tags = merge(var.common_tags, { Name = "my-demo-redis-subnet-group" })
}

#####################################################################
# Redis Cluster Configuration
#####################################################################

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "my-demo-redis"
  description                  = "Redis cluster for My Demo application"
  
  # Базові налаштування Redis
  engine                      = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t3.micro"
  port                       = 6379
  
  # Налаштування кластера
  num_cache_clusters         = 1
  
  # Мережеві налаштування
  subnet_group_name         = aws_elasticache_subnet_group.this.name
  security_group_ids        = [aws_security_group.redis_sg.id]
  
  tags = merge(var.common_tags, {
    Name    = "my-demo-redis"
    Service = "redis"
  })
}