terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "firstvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "supervpc"
  }
}

resource "aws_subnet" "firstvpc_public_subnet" {
  vpc_id                  = aws_vpc.firstvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "firstvpc-public"
  }
}

resource "aws_subnet" "firstvpc_private_subnet" {
  vpc_id                  = aws_vpc.firstvpc.id
  cidr_block              = "10.0.2.0/24"

  tags = {
    Name = "firstvpc-pivate"
  }
}

resource "aws_internet_gateway" "firstvpc_internet_gateway" {
  vpc_id = aws_vpc.firstvpc.id

  tags = {
    Name = "firstvpc-igw"
  }
}

resource "aws_eip" "ip" {
  tags = {
    Name = "firstvpc_elasticIP"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.ip.id
  subnet_id     =  aws_subnet.firstvpc_public_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}


resource "aws_route_table" "firstvpc_public_rt" {
  vpc_id = aws_vpc.firstvpc.id

  tags = {
    Name = "firstvpc_public_route"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.firstvpc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.firstvpc_internet_gateway.id
}

resource "aws_route_table_association" "firstvpc_public_rt" {
  subnet_id      = aws_subnet.firstvpc_public_subnet.id
  route_table_id = aws_route_table.firstvpc_public_rt.id
}

resource "aws_route_table" "firstvpc_private_rt" {
  vpc_id = aws_vpc.firstvpc.id

  tags = {
    Name = "firstvpc_private_route"
  }
}

resource "aws_route" "default_route_1" {
  route_table_id         = aws_route_table.firstvpc_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gateway.id
}

resource "aws_route_table_association" "firstvpc_private_rt_1" {
  subnet_id      = aws_subnet.firstvpc_private_subnet.id
  route_table_id = aws_route_table.firstvpc_private_rt.id
}

resource "aws_security_group" "firstvpc_sg" {
  name        = "firstvpc_sg"
  description = "firstvpc security group"
  vpc_id      = aws_vpc.firstvpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}




resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf-key-pair" {
  key_name   = "tf-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}


resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair.pem"
}

resource "aws_instance" "public_linux" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "tf-key-pair"
  subnet_id     = aws_subnet.firstvpc_public_subnet.id
  vpc_security_group_ids = [aws_security_group.firstvpc_sg.id] 

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  echo "*** Completed Installing apache2"
  EOF


  tags = {
    Name = "super_public_linux"
  }
}

resource "aws_instance" "private_linux" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "tf-key-pair"
  subnet_id     = aws_subnet.firstvpc_private_subnet.id
  vpc_security_group_ids = [aws_security_group.firstvpc_sg.id] 

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  echo "*** Completed Installing apache2"
  EOF

  tags = {
    Name = "super_private_linux"
  }
}
