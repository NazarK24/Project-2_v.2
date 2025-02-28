variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "frontend_container_port" {
  type    = number
  default = 8000
}

variable "common_tags" {
  type = map(string)
}

variable "backend_rds_container_port" {
  type    = number
  default = 8001
}

variable "backend_redis_container_port" {
  type    = number
  default = 8002
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-demo"
}