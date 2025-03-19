output "alb_dns_name" {
  description = "DNS name of the ALB"
  value = aws_lb.frontend_alb.dns_name
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value = aws_security_group.alb_sg.id
}

output "alb_logs_bucket" {
  description = "ID of the ALB logs bucket"
  value = aws_s3_bucket.alb_logs.id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  value = aws_lb.frontend_alb.arn_suffix
}

# Нові вихідні значення для бекенд Target Groups
output "backend_rds_target_group_arn" {
  description = "ARN of the backend RDS target group"
  value       = aws_lb_target_group.backend_rds.arn
}

output "backend_redis_target_group_arn" {
  description = "ARN of the backend Redis target group"
  value       = aws_lb_target_group.backend_redis.arn
}

# Нові вихідні значення для Listener ARN
output "backend_rds_listener_arn" {
  description = "ARN of the backend RDS listener"
  value       = aws_lb_listener.backend_rds_listener.arn
}

output "backend_redis_listener_arn" {
  description = "ARN of the backend Redis listener"
  value       = aws_lb_listener.backend_redis_listener.arn
}
