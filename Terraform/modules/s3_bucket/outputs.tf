output "frontend_bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.frontend_static.id
}

output "frontend_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.frontend_static.arn
}

output "frontend_bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend_static.bucket_regional_domain_name
}

output "frontend_bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.frontend_static.website_endpoint
} 