# https://www.youtube.com/watch?v=DE-QsqmzMPw&list=PLXH6fsPmiZS7BbPtouAIlpduTau2x60Fh&index=3(vpc tutorial)

provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "devops" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops"
  }
}

# Create subnets in VPC
resource "aws_subnet" "devops-public-1" {
  vpc_id                  = aws_vpc.devops.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "devops-public-1"
  }
}

resource "aws_subnet" "devops-public-2" {
  vpc_id                  = aws_vpc.devops.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "devops-public-2"
  }
}

resource "aws_subnet" "devops-private-1" {
  vpc_id                  = aws_vpc.devops.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "devops-private-1"
  }
}
resource "aws_subnet" "devops-private-2" {
  vpc_id                  = aws_vpc.devops.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name = "devops-private-2"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "devops-gw" {
  vpc_id = aws_vpc.devops.id

  tags = {
    Name = "devops-gw"
  }
}
# Define Routing table for VPC
resource "aws_route_table" "devops-public" {
  vpc_id = aws_vpc.devops.id

  route {
    cidr_block = "0.0.0.0/0" # all IPs
    gateway_id = aws_internet_gateway.devops-gw.id
  }

  tags = {
    Name = "devops-public"
  }
}
# Define Routing association between a route table and Subnet , route table and internet gateway virtual private gateway
resource "aws_route_table_association" "devops-public-1" {
  subnet_id      = aws_subnet.devops-public-1.id
  route_table_id = aws_route_table.devops-public.id
}

# resource "aws_route_table_association" "devops-public-2" {
#   gateway_id     = aws_subnet.devops-public-2.id
#   route_table_id = aws_route_table.devops-public.id
# }

#Define external IP - NAT Gateway - use NAT gateway in private VPC subnet to connect Internet
resource "aws_eip" "devops-nat" {
  vpc = true
}

resource "aws_nat_gateway" "devops-nat-gw" {
  allocation_id = aws_eip.devops-nat.id
  subnet_id     = aws_subnet.devops-public-1.id
  depends_on    = [aws_internet_gateway.devops-gw]
}

resource "aws_route_table" "devops-private" {
  vpc_id = aws_vpc.devops.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devops-nat-gw.id
  }

  tags = {
    "Name" = "devops-private"
  }
}

# Route assciation private
resource "aws_route_table_association" "devops-private-1" {
  subnet_id      = aws_subnet.devops-private-1.id
  route_table_id = aws_route_table.devops-private.id
}

#Sercurity
resource "aws_security_group" "instance" {
  description = "Allow traffic for instances"
  tags = {
    "Name" = "devops-port"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}