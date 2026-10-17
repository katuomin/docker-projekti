# Use one available AZ for this small example. A production deployment would
# normally span multiple AZs and use private subnets for application services.
data "aws_availability_zones" "available" {
  state = "available"
}

# Select the latest Ubuntu 24.04 LTS x86_64 AMI published by Canonical.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# A small VPC with one public subnet gives the instance internet access for
# cloning the repository and downloading container images.
resource "aws_vpc" "example" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "docker-projekti-example"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "docker-projekti-example"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "docker-projekti-example-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "docker-projekti-example-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Keep the same externally reachable ports as docker-compose.yaml:
# 8080 serves the nginx proxy and 3000 exposes the notes API directly.
# Port 22 is intentionally not opened; use AWS Systems Manager Session Manager.
resource "aws_security_group" "instance" {
  name        = "docker-projekti-example"
  description = "Web proxy and API ports for the Compose example"
  vpc_id      = aws_vpc.example.id

  ingress {
    description = "Compose nginx proxy"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Compose notes API (direct access, as in docker-compose.yaml)"
    from_port   = 3000
    to_port     = 3000
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
    Name = "docker-projekti-example"
  }
}

# This role lets you open a shell through Session Manager without exposing SSH.
resource "aws_iam_role" "instance" {
  name = "docker-projekti-example-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "session_manager" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "docker-projekti-example-ec2"
  role = aws_iam_role.instance.name
}

# Cloud-init installs Docker Compose, clones the selected branch, and runs the
# existing Compose file. The instance keeps the database volume on its disk.
resource "aws_instance" "example" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  iam_instance_profile        = aws_iam_instance_profile.instance.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url    = var.repository_url
    repository_branch = var.repository_branch
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 16
    volume_type = "gp3"
  }

  depends_on = [
    aws_iam_role_policy_attachment.session_manager,
    aws_route_table_association.public,
  ]

  tags = {
    Name = "docker-projekti-example"
  }
}
