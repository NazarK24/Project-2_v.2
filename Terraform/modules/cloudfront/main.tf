resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = var.s3_website_endpoint
    origin_id   = "S3-${var.project_name}-${var.environment}-frontend-static"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} frontend distribution"
  default_root_object = "index.html"

  # Кеш-поведінка за замовчуванням для статичних файлів з S3
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.project_name}-${var.environment}-frontend-static"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-frontend-distribution"
    },
  )

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name = "${var.project_name}-${var.environment}-cors-policy"
  
  cors_config {
    access_control_allow_credentials = true
    
    access_control_allow_headers {
      items = [
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "User-Agent",
        "DNT",
        "Cache-Control",
        "X-Mx-ReqToken",
        "Keep-Alive",
        "X-Requested-With",
        "X-CSRF-Token",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]
    }
    
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    }
    
    access_control_allow_origins {
      items = ["*"]  # У продакшні слід замінити на конкретні домени
    }
    
    access_control_max_age_sec = 600
    origin_override = true
  }
} 