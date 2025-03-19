output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "redis_endpoint" {
  value = module.redis.redis_endpoint
}

output "s3_frontend_website_endpoint" {
  description = "S3 website endpoint for static frontend"
  value       = module.s3_bucket.frontend_bucket_website_endpoint
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for static frontend"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "backend_api_endpoints" {
  description = "Endpoints для доступу до бекенд сервісів через ALB"
  value = {
    rds_endpoint   = "http://${module.alb.alb_dns_name}:8001/test_connection/"
    redis_endpoint = "http://${module.alb.alb_dns_name}:8002/test_connection/"
  }
}
