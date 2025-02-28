output "frontend_repo_url" {
  value = aws_ecr_repository.frontend_repo.repository_url
}

output "backend_rds_repo_url" {
  value = aws_ecr_repository.backend_rds_repo.repository_url
}

output "backend_redis_repo_url" {
  value = aws_ecr_repository.backend_redis_repo.repository_url
}
