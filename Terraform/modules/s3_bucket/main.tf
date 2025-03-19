resource "aws_s3_bucket" "frontend_static" {
  bucket = "${var.project_name}-${var.environment}-frontend-static"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-frontend-static"
    },
  )
}

resource "aws_s3_bucket_ownership_controls" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "frontend_static" {
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend_static,
    aws_s3_bucket_public_access_block.frontend_static,
  ]

  bucket = aws_s3_bucket.frontend_static.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.frontend_static.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.frontend_static.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_versioning" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "Content-Length", "Content-Type"]
    max_age_seconds = 3600
  }
} 