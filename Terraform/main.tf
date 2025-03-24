#####################################################################
# Data Sources
#####################################################################

data "aws_region" "current" {}

#####################################################################
# Security Groups Configuration
#####################################################################

# Security Group для VPC Endpoints
# Контролює доступ до AWS сервісів через VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name   = "vpc-endpoints-sg"
  vpc_id = module.vpc.vpc_id

  # Дозволяємо вхідний HTTPS трафік від ECS задач
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.ecs.ecs_sg_id]
    description     = "Allow HTTPS from ECS tasks"
  }

  # Дозволяємо вихідний HTTPS трафік
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound"
  }

  tags = merge(var.common_tags, { Name = "vpc-endpoints-sg" })
}

#####################################################################
# VPC Endpoints Configuration
#####################################################################

# Gateway Endpoint для S3
# Дозволяє доступ до S3 без виходу в інтернет
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [module.vpc.private_route_table_id]

  tags = merge(var.common_tags, { Name = "s3-endpoint" })

  depends_on = [module.ecs]
  
  timeouts {
    delete = "20m"
  }
}

# ECR API endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, { Name = "ecr-api-endpoint" })

  depends_on = [module.ecs]
  
  timeouts {
    delete = "20m"
  }
}

# ECR Docker endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, { Name = "ecr-dkr-endpoint" })

  depends_on = [module.ecs]
  
  timeouts {
    delete = "20m"
  }
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, { Name = "logs-endpoint" })

  depends_on = [module.ecs]
  
  timeouts {
    delete = "20m"
  }
}

#####################################################################
# Networking Infrastructure
#####################################################################

# VPC Module
# Створює основну мережеву інфраструктуру
module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr_1  = var.public_subnet_cidr_1
  public_subnet_cidr_2  = var.public_subnet_cidr_2
  private_subnet_cidr_1 = var.private_subnet_cidr_1
  private_subnet_cidr_2 = var.private_subnet_cidr_2  
  common_tags           = var.common_tags
}

# ALB Module
# Керує балансувальником навантаження для бекендів
module "alb" {
  source = "./modules/alb"
  
  vpc_id                 = module.vpc.vpc_id
  public_subnets        = module.vpc.public_subnets
  common_tags           = var.common_tags
}

#####################################################################
# Container Infrastructure
#####################################################################

# ECR Module
# Керує репозиторіями контейнерів
module "ecr" {
  source      = "./modules/ecr"
  common_tags = var.common_tags

  # Налаштування репозиторіїв
  frontend_repo_name      = "my-demo-frontend"
  backend_rds_repo_name   = "my-demo-backend-rds"
  backend_redis_repo_name = "my-demo-backend-redis"
  
  # Теги для образів
  frontend_image_tag      = var.frontend_image_tag
  backend_rds_image_tag   = var.backend_rds_image_tag
  backend_redis_image_tag = var.backend_redis_image_tag
}

# ECS Module
# Керує кластером контейнерів та сервісами
module "ecs" {
  source = "./modules/ecs"

  # Базова конфігурація
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  ecs_cluster_name = "my-demo-ecs-cluster"
  common_tags      = var.common_tags
  
  # Налаштування бекенд контейнерів
  backend_rds_image_url   = "${module.ecr.backend_rds_repo_url}:${var.backend_rds_image_tag}"
  backend_redis_image_url = "${module.ecr.backend_redis_repo_url}:${var.backend_redis_image_tag}"

  # Налаштування бази даних
  db_host     = module.rds.rds_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  # Налаштування Redis
  redis_host     = module.redis.redis_endpoint
  redis_db       = "0"

  # Налаштування балансувальника навантаження (тільки для бекендів)
  alb_sg_id                   = module.alb.alb_sg_id
  backend_rds_target_group_arn = module.alb.backend_rds_target_group_arn
  backend_redis_target_group_arn = module.alb.backend_redis_target_group_arn
  alb_dns_name               = module.alb.alb_dns_name

  # Security Groups
  rds_sg_id           = module.rds.rds_sg_id
  redis_sg_id         = module.redis.redis_sg_id
  vpc_endpoints_sg_id = aws_security_group.vpc_endpoints.id

  # Додаємо CloudFront домен для CORS
  cloudfront_domain = module.cloudfront.cloudfront_distribution_domain_name
}

#####################################################################
# Database Infrastructure
#####################################################################

# RDS Module
# Керує PostgreSQL базою даних
module "rds" {
  source          = "./modules/rds"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password
  common_tags     = var.common_tags
  ecs_sg_id       = module.ecs.ecs_sg_id
}

# Redis Module
# Керує Redis кластером
module "redis" {
  source          = "./modules/redis"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  common_tags     = var.common_tags
  ecs_sg_id       = module.ecs.ecs_sg_id
}

#####################################################################
# Frontend Static Website Infrastructure
#####################################################################

# S3 Bucket Module
# Зберігає статичні файли фронтенду
module "s3_bucket" {
  source       = "./modules/s3_bucket"
  project_name = var.project
  environment  = var.environment
  common_tags  = var.common_tags
}

# CloudFront Module
# Розподіляє статичний контент через CDN
module "cloudfront" {
  source             = "./modules/cloudfront"
  s3_website_endpoint = module.s3_bucket.frontend_bucket_website_endpoint
  project_name       = var.project
  environment        = var.environment
  common_tags        = var.common_tags
}