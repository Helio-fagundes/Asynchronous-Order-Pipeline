#==========================================
#Criação da VPC
#==========================================
resource "aws_vpc" "vpc_main" {
  tags = {
    Name = "vpc-helio-terraform-assynchronous"
  }
  instance_tenancy     = "default"
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

#==========================================
#Criação das subnet publicas
#==========================================
resource "aws_subnet" "subnet_public_a" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-public-a"
  }
}

resource "aws_subnet" "subnet_public_b" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-public-b"
  }
}

#==========================================
#Criação das subnet privadas
#==========================================
resource "aws_subnet" "subnet_private_a" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "subnet-private-a"
  }
}

resource "aws_subnet" "subnet_private_b" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "subnet-private-b"
  }
}

#==========================================
#Criação da internet gateway
#==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "igw-helio-terraform"
  }
}

#==========================================
#Criação da Route Table
#==========================================
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route-table-public-igw"
  }
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "route-table-private-endpoints"
  }
}

#==========================================
#Criação das associações da Route Table
#==========================================
resource "aws_route_table_association" "rt_public_a" {
  subnet_id      = aws_subnet.subnet_public_a.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "rt_public_b" {
  subnet_id      = aws_subnet.subnet_public_b.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "rt_private_a" {
  subnet_id      = aws_subnet.subnet_private_a.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_route_table_association" "rt_private_b" {
  subnet_id      = aws_subnet.subnet_private_b.id
  route_table_id = aws_route_table.route_table_private.id
}

#==========================================
#Criação das vpc endpoint
#==========================================

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc_main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
  security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc_main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
  security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.vpc_main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.route_table_private.id]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc_main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
  security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.vpc_main.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
  security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.vpc_main.id
  service_name        = "com.amazonaws.us-east-1.sns"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet_private_a.id, aws_subnet.subnet_private_b.id]
  security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.vpc_main.id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.route_table_private.id]
}