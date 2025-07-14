terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable my_ip {}
variable instance_type {}
variable "public_key_location" {
 default = "C:/Users/HP/.ssh/id_ed25519.pub"
}



resource "aws_vpc" "server_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc" 
    }
}


resource "aws_subnet" "server_subnet_1" {
  vpc_id            = aws_vpc.server_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}


resource "aws_route_table" "server_route_table" {
  vpc_id = aws_vpc.server_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.server_igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}




output "ec2_pulic_ip" {
  value = aws_instance.server_server.public_ip
  
}

resource "aws_key_pair" "ssh-key" {
  key_name = "mine-key"
  public_key = file(var.public_key_location)
}


resource "aws_internet_gateway" "server_igw" {
  vpc_id = aws_vpc.server_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "a_rtb_subnet" {
  subnet_id      = aws_subnet.server_subnet_1.id      
  route_table_id = aws_route_table.server_route_table.id
}




resource "aws_security_group" "server_sg" {
  name        = "server-sg"
  description = "Security group for server instances"
  vpc_id      = aws_vpc.server_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }


  egress { 
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}







resource "aws_instance" "server_server" {
  ami                         = data.aws_ami.latest_amazon_linux_image.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.server_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.server_sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                     = aws_key_pair.ssh-key.key_name



user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
usermod -aG docker ec2-user
docker run -d -p 8080:80 nginx
EOF


  tags = {
    Name = "${var.env_prefix}-server"
  }
}

