output "redis_endpoint" {
  description = "Redis endpoint"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "redis_sg_id" {
  description = "Redis security group ID"
  value       = aws_security_group.redis_sg.id
}