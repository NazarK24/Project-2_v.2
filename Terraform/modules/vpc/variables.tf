variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr_1" {
  type = string
}
variable "public_subnet_cidr_2" {
  type = string
}
variable "private_subnet_cidr_1" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.5.0/24"
}
variable "private_subnet_cidr_2" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.6.0/24"
}
variable "common_tags" {
  type = map(string)
}
