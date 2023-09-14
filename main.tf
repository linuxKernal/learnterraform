terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "ap-south-1"
}

# https://www.youtube.com/watch?v=yOs7-DcKzCY vpc peering connection

# Create a VPC
resource "aws_vpc" "firstvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "firstvpc"
  }
}

resource "aws_vpc" "secondvpc" {
  cidr_block = "11.0.0.0/16"
  tags = {
    Name = "secondvpc"
  }
}

# Create subnet
resource "aws_subnet" "firstvpc_public_subnet" {
  vpc_id                  = aws_vpc.firstvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "firstvpc-public"
  }
}

resource "aws_subnet" "firstvpc_private_subnet" {
  vpc_id     = aws_vpc.firstvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "firstvpc-private"
  }
}



resource "aws_subnet" "secondvpc_private1_subnet" {
  vpc_id            = aws_vpc.secondvpc.id
  cidr_block        = "11.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "second-pivate1-subnet"
  }
}

# us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1e, us-east-1f

resource "aws_subnet" "secondvpc_private2_subnet" {
  vpc_id            = aws_vpc.secondvpc.id
  cidr_block        = "11.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "second-pivate2-subnet"
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
  subnet_id     = aws_subnet.firstvpc_public_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}


resource "aws_route_table" "firstvpc_public_rt" {
  vpc_id = aws_vpc.firstvpc.id

  tags = {
    Name = "firstvpc_public_rt"
  }
}

resource "aws_route_table" "firstvpc_private_rt" {
  vpc_id = aws_vpc.firstvpc.id

  tags = {
    Name = "firstvpc_private_rt"
  }
}

# resource "aws_route_table" "secondvpc_private1_rt" {
#   vpc_id = aws_vpc.secondvpc.id

#   tags = {
#     Name = "secondvpc_private1_rt"
#   }
# }

# resource "aws_route_table" "secondvpc_private2_rt" {
#   vpc_id = aws_vpc.secondvpc.id

#   tags = {
#     Name = "secondvpc_private2_rt"
#   }
# }

resource "aws_route" "firstvpc_igw_default_route" {
  route_table_id         = aws_route_table.firstvpc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.firstvpc_internet_gateway.id
}

resource "aws_route_table_association" "firstvpc_public_rt" {
  subnet_id      = aws_subnet.firstvpc_public_subnet.id
  route_table_id = aws_route_table.firstvpc_public_rt.id
}


resource "aws_route" "firstvpc_nat_default_route" {
  route_table_id         = aws_route_table.firstvpc_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gateway.id
}

resource "aws_route_table_association" "firstvpc_private_rt" {
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

resource "aws_security_group" "secondvpc_sg" {
  name        = "secondvpc_sg"
  description = "secondvpc security group"
  vpc_id      = aws_vpc.secondvpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
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

resource "aws_instance" "firstvpc_public_ec2" {
  ami                    = "ami-05dbd1926bfb06723"
  instance_type          = "t2.micro"
  key_name               = "tf-key-pair"
  subnet_id              = aws_subnet.firstvpc_public_subnet.id
  vpc_security_group_ids = [aws_security_group.firstvpc_sg.id]

  tags = {
    Name = "firstvpc_public_ec2"
  }
}

resource "aws_instance" "firstvpc_private_ec2" {
  ami                    = "ami-0f5ee92e2d63afc18"
  instance_type          = "t2.micro"
  key_name               = "tf-key-pair"
  subnet_id              = aws_subnet.firstvpc_private_subnet.id
  vpc_security_group_ids = [aws_security_group.firstvpc_sg.id]


  tags = {
    Name = "firstvpc_private_ec2"
  }
}

resource "aws_vpc_peering_connection" "superpeering" {
  peer_vpc_id = aws_vpc.firstvpc.id
  vpc_id      = aws_vpc.secondvpc.id

  tags = {
    Name = "super vpc peering connection"
  }
}

resource "aws_vpc_peering_connection_accepter" "accept" {
  auto_accept               = true
  vpc_peering_connection_id = aws_vpc_peering_connection.superpeering.id
}

resource "aws_route" "firstvpc_peer_default_route" {
  route_table_id         = aws_route_table.firstvpc_public_rt.id
  destination_cidr_block = "11.0.0.0/16"
  gateway_id             = aws_vpc_peering_connection.superpeering.id
}

resource "aws_route" "firstvpc_peer_default_route_1" {
  route_table_id         = aws_route_table.firstvpc_private_rt.id
  destination_cidr_block = "11.0.0.0/16"
  gateway_id             = aws_vpc_peering_connection.superpeering.id
}

resource "aws_route" "secondvpc_peer_default_route" {
  route_table_id         = aws_vpc.secondvpc.main_route_table_id
  destination_cidr_block = "10.0.0.0/16"
  gateway_id             = aws_vpc_peering_connection.superpeering.id
}

resource "aws_db_subnet_group" "my_db_pg_subnet_group" {
  name       = "my-db-pg-subnet-group"
  subnet_ids = [aws_subnet.secondvpc_private1_subnet.id, aws_subnet.secondvpc_private2_subnet.id]
}


resource "aws_db_instance" "my_rds_pg_instance" {
  allocated_storage          = 20
  engine                     = "postgres"
  db_name                    = "postgres"
  engine_version             = "15.3"
  instance_class             = "db.t3.micro"
  storage_type               = "gp2"
  username                   = "root"
  password                   = "super1234"
  auto_minor_version_upgrade = false
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.my_db_pg_subnet_group.name
  vpc_security_group_ids     = [aws_security_group.secondvpc_sg.id]
}


output "public_EC2_public_ip" {
  value = aws_instance.firstvpc_public_ec2.public_ip
}

output "private_EC2_private_ip" {
  value = aws_instance.firstvpc_private_ec2.private_ip
}

output "postgres_RDS_Endpoint" {
  value = aws_db_instance.my_rds_pg_instance.endpoint
}
