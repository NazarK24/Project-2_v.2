output "alb_dns_name" {
  description = "DNS name of the ALB"
  value = aws_lb.frontend_alb.dns_name
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value = aws_lb_target_group.frontend.arn
}

output "frontend_listener_arn" {
  description = "ARN of the frontend listener"
  value = aws_lb_listener.frontend_listener.arn
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

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  value = aws_lb_target_group.frontend.arn_suffix
}
