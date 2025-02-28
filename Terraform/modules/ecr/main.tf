resource "aws_ecr_repository" "frontend_repo" {
  name = var.frontend_repo_name
  tags = merge(var.common_tags, { Name = var.frontend_repo_name })
}

resource "aws_ecr_repository" "backend_rds_repo" {
  name = var.backend_rds_repo_name
  tags = merge(var.common_tags, { Name = var.backend_rds_repo_name })
}

resource "aws_ecr_repository" "backend_redis_repo" {
  name = var.backend_redis_repo_name
  tags = merge(var.common_tags, { Name = var.backend_redis_repo_name })
}
