variable "frontend_repo_name" {
  type = string
}
variable "backend_rds_repo_name" {
  type = string
}
variable "backend_redis_repo_name" {
  type = string
}
variable "common_tags" {
  type = map(string)
}
variable "frontend_image_tag" {
  type    = string
  default = "latest"
}
variable "backend_rds_image_tag" {
  type    = string
  default = "latest"
}
variable "backend_redis_image_tag" {
  type    = string
  default = "latest"
}
