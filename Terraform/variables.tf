#####################################################################
# Network Configuration Variables
#####################################################################

# Основна CIDR адреса для VPC
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Налаштування публічних підмереж
variable "public_subnet_cidr_1" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  type    = string
  default = "10.0.2.0/24"
}

# Налаштування приватних підмереж
variable "private_subnet_cidr_1" {
  type    = string
  default = "10.0.3.0/24"
}

variable "private_subnet_cidr_2" {
  type    = string
  default = "10.0.4.0/24"
}

#####################################################################
# Application Configuration Variables
#####################################################################

# Порт для frontend контейнера
variable "frontend_container_port" {
  type    = number
  default = 8000
}

# Теги для образів контейнерів
variable "frontend_image_tag" {
  type    = string
  default = "latest"
}

variable "backend_rds_image_tag" {
  type    = string
  default = "latest"
}

variable "backend_redis_image_tag" {
  type    = string
  default = "latest"
}

#####################################################################
# Database Configuration Variables
#####################################################################

# PostgreSQL налаштування
variable "db_name" {
  type    = string
  default = "postgres"
}

variable "db_username" {
  type    = string
  default = "mypostgres"
}

variable "db_password" {
  type        = string
  description = "Password for the database"
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "The db_password must be at least 16 characters long"
  }
}

#####################################################################
# Environment and Project Variables
#####################################################################

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "my-demo"
}

# Загальні теги для всіх ресурсів
variable "common_tags" {
  type = map(string)
  default = {
    Project     = "my-demo"
    Environment = "dev"
  }
}

#####################################################################
# ECS Configuration Variables
#####################################################################

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "ecs_min_count" {
  type    = number
  default = 1
}

variable "ecs_max_count" {
  type    = number
  default = 3
}
