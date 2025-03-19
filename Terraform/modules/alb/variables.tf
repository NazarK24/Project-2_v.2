variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "common_tags" {
  type = map(string)
}

variable "backend_rds_container_port" {
  description = "The port on which the backend RDS container will run"
  type        = number
  default     = 8001
}

variable "backend_redis_container_port" {
  description = "The port on which the backend Redis container will run"
  type        = number
  default     = 8002
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "my-demo"
}