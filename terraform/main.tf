provider "aws" {
  region = "us-east-1"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets in us-east-1a
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

# Select the first subnet in us-east-1a
data "aws_subnet" "selected" {
  id = tolist(data.aws_subnets.selected.ids)[0]
}

# Load SSH Public Key
resource "aws_key_pair" "my_key" {
  key_name   = "assignkey"
  public_key = file("assignkey.pub")
}

# Security Group for SSH and Web Access
resource "aws_security_group" "web_sg" {
  name_prefix = "web_sg_"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy EC2 Instance in us-east-1a
resource "aws_instance" "web_server" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type               = "t3.medium"
  subnet_id                   = data.aws_subnet.selected.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key.key_name
  security_groups             = [aws_security_group.web_sg.id]
  availability_zone           = "us-east-1a"  # Force EC2 into us-east-1a

  tags = {
    Name = "web_server"
  }

  depends_on = [aws_security_group.web_sg]
}

# Create Amazon ECR Repositories
resource "aws_ecr_repository" "webapp_repo" {
  name = "webapp_repo"
}

resource "aws_ecr_repository" "mysql_repo" {
  name = "mysql_repo"
}
