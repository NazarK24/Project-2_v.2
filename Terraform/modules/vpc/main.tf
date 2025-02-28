#####################################################################
# VPC Configuration
#####################################################################

data "aws_region" "current" {}

# Основна VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    { Name = "my-demo-vpc" }
  )
}

# Internet Gateway для публічного доступу
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-igw" })
}

#####################################################################
# Availability Zones Configuration
#####################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

#####################################################################
# Subnet Configuration
#####################################################################

# Публічні підмережі
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]
  
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "public-subnet-1" })
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]
  
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "public-subnet-2" })
}

# Приватні підмережі
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]
}

#####################################################################
# Route Tables Configuration
#####################################################################

# Публічна таблиця маршрутизації
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-public-rt" })
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Асоціації публічних підмереж
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Приватна таблиця маршрутизації
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "my-demo-private-rt" })
}

# Асоціації приватних підмереж
resource "aws_route_table_association" "private_assoc_1" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_1.id
}

resource "aws_route_table_association" "private_assoc_2" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_2.id
}

#####################################################################
# NAT Gateway Configuration
#####################################################################

# Elastic IP для NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "nat-eip" })
}

# NAT Gateway для приватних підмереж
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id  # Розміщуємо в першій публічній підмережі

  depends_on = [aws_internet_gateway.this]
  
  tags = merge(var.common_tags, { Name = "main-nat-gateway" })
}

# Маршрут через NAT Gateway для приватних підмереж
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
