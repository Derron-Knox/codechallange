# create VPC
resource "aws_vpc" "docker" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "docker"
  }

}

# create internet gateway
resource "aws_internet_gateway" "wp_ig" {
  vpc_id = aws_vpc.docker.id
  tags = {
    "Name" = "wp_igw"
  }
}

# create eip for NAT gateway
resource "aws_eip" "ngweip" {
  vpc = true
}

# create NAT gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.ngweip.id
  subnet_id     = aws_subnet.pubsub-1.id
  depends_on    = [aws_internet_gateway.wp_ig]
}

# create public route table
resource "aws_route_table" "wp_pub" {
  vpc_id = aws_vpc.docker.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_ig.id
  }
  tags = {
    "Name" = "wp_rt_pub"
  }
}

# create private route table
resource "aws_route_table" "wp_priv" {
  vpc_id = aws_vpc.docker.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    "Name" = "wp_rt_priv"
  }
}

# grab availablity zones
data "aws_availability_zones" "available" {
  state = "available"
}

# create public subnets
resource "aws_subnet" "pubsub-1" {
  vpc_id            = aws_vpc.docker.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    "Name" = "wp_pub1"
  }
}

resource "aws_subnet" "pubsub-2" {
  vpc_id            = aws_vpc.docker.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    "Name" = "wp_pub2"
  }
}

resource "aws_subnet" "pubsub-3" {
  vpc_id            = aws_vpc.docker.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[3]
  tags = {
    "Name" = "wp_pub3"
  }
}

# create private subnet
resource "aws_subnet" "privsub" {
  vpc_id            = aws_vpc.docker.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    "Name" = "wp_priv"
  }
}

# associate public subnets with public route table

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.pubsub-1.id
  route_table_id = aws_route_table.wp_pub.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.pubsub-2.id
  route_table_id = aws_route_table.wp_pub.id
}

resource "aws_route_table_association" "pub3" {
  subnet_id      = aws_subnet.pubsub-3.id
  route_table_id = aws_route_table.wp_pub.id
}

resource "aws_main_route_table_association" "priv1" {
  vpc_id         = aws_vpc.docker.id
  route_table_id = aws_route_table.wp_priv.id
}