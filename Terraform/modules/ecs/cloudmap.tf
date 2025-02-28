resource "aws_service_discovery_private_dns_namespace" "ecs_namespace" {
  name        = "my-demo.local"
  description = "Namespace for ECS services"
  vpc         = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "my-demo-namespace"
  })
}

resource "aws_service_discovery_service" "frontend" {
  name = "frontend-service"
  namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.common_tags, {
    Name = "frontend-discovery-service"
  })
}

resource "aws_service_discovery_service" "backend_rds" {
  name = "rds"
  namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    dns_records {
      ttl  = 5
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.common_tags, {
    Name = "backend-rds-discovery"
  })
}

resource "aws_service_discovery_service" "backend_redis" {
  name = "redis"
  namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    dns_records {
      ttl  = 5
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.common_tags, {
    Name = "backend-redis-discovery"
  })
} 