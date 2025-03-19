variable "s3_website_endpoint" {
  description = "The website endpoint URL of the S3 bucket"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g. dev, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "alb_dns_name" {
  description = "DNS name of the ALB for backend services"
  type        = string
} 