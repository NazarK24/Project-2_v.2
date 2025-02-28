# VPC and Network
variable "vpc_id" {
  type        = string
  description = "ID of the VPC where resources will be created"
}

variable "private_subnets" {
  type = list(string)
}

# ECS Cluster
variable "ecs_cluster_name" {
  type = string
}

variable "ecs_instance_type" {
  type    = string
  default = "t3.micro"
}

# Security Groups
variable "alb_sg_id" {
  type = string
}

variable "rds_sg_id" {
  type = string
}

variable "redis_sg_id" {
  type = string
}

variable "vpc_endpoints_sg_id" {
  type        = string
  description = "ID of the VPC endpoints security group"
}

# Frontend Variables
variable "frontend_container_port" {
  type    = number
  default = 8000
}

variable "frontend_target_group_arn" {
  type = string
}

variable "frontend_listener_arn" {
  type = string
}

variable "frontend_image_url" {
  type        = string
  description = "URL for frontend container image"
}

variable "frontend_desired_count" {
  default = 1
}

# Backend RDS Variables
variable "backend_rds_image_url" {
  type = string
}

variable "backend_rds_container_port" {
  type    = number
  default = 8001
}

variable "backend_rds_desired_count" {
  default = 1
}

# Backend Redis Variables
variable "backend_redis_image_url" {
  type = string
}

variable "backend_redis_container_port" {
  type    = number
  default = 8002
}

variable "backend_redis_desired_count" {
  default = 1
}

# Database Variables
variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "db_host" {
  type        = string
  description = "Database host endpoint"
}

# Redis Variables
variable "redis_host" {
  type        = string
  description = "Redis host endpoint"
}

variable "redis_db" {
  type        = string
  description = "Redis database number"
  default     = "0"
}

# ALB Variables
variable "alb_dns_name" {
  type        = string
  description = "DNS name of the Application Load Balancer"
}

# Tags
variable "common_tags" {
  type = map(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-demo"
}