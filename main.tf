provider "aws" {
  region = "us-east-1"
  profile = "default"
}

variable "desafio_cloud_devops" {
  description = "Projeto do desafio para estagio em cloud devops na VExpenses"
  type        = string
  default     = "VExpenses"
}

variable "Jeova" {
  description = "Nome do candidato é Jeova"
  type        = string
  default     = "Jeova"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.desafio_cloud_devops}-${var.Jeova}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-igw"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

variable "allowed_ssh_ip" {
  description = "Endereço IP para permitir SSH"
  type        = string
  default     = "203.0.113.0/32"
}

resource "aws_security_group" "main_sg" {
  name        = "${var.desafio_cloud_devops}-${var.Jeova}-sg"
  description = "Permitir SSH de IP confiavel e todo o trafego de saida"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    description      = "Permitir todo o trafego de saida"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.desafio_cloud_devops}-${var.Jeova}-sg"
  }
}

data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

resource "aws_instance" "debian_ec2" {
    ami                    = data.aws_ami.debian12.id
    instance_type         = "t2.micro"
    subnet_id             = aws_subnet.main_subnet.id
    key_name              = aws_key_pair.ec2_key_pair.key_name
    vpc_security_group_ids = [aws_security_group.main_sg.id]

    associate_public_ip_address = true

    root_block_device {
        volume_size           = 20
        volume_type           = "gp2"
        delete_on_termination = true
        encrypted             = true
    }

    user_data = <<-EOF
        #!/bin/bash
        apt-get update -y
        apt-get upgrade -y
        apt-get install nginx -y
        systemctl start nginx
        systemctl enable nginx
    EOF

    tags = {
        Name = "${var.desafio_cloud_devops}-${var.Jeova}-ec2"
    }
}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/private_key.pem"
  file_permission = "0400"
}

output "private_key_path" {
  description = "Caminho para a chave privada localmente armazenada"
  value       = local_file.private_key.filename
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
