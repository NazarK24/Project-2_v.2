provider "aws" {
  region  = "eu-north-1"
  profile = "default"
  
  default_tags {
    tags = var.common_tags
  }
} 