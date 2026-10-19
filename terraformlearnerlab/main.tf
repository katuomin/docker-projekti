# AWS learner lab compatible terraform script

# Use the account's default VPC and one of its default subnets instead of
# building our own network.
data "aws_vpc" "default" {
  default = true
}

# Latest Ubuntu 24.04 LTS x86_64 AMI published by Canonical.
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

# Only the nginx proxy (port 80) is public; it also forwards /api/ to the API.
# Port 22 is opened for SSH with the lab's vockey key because Session Manager
# may not be usable with the lab role.
resource "aws_security_group" "instance" {
  name_prefix = "docker-projekti-lab-"
  description = "Web proxy, API and SSH for the Compose example"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Compose nginx proxy"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docker-projekti-lab"
  }
}

# Cloud-init installs Docker, clones the repo and runs the Compose file.
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  # No subnet_id: AWS picks a default subnet in an AZ that supports the
  # instance type 
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true

  # Empty string becomes null so the attribute is simply omitted.
  iam_instance_profile = var.instance_profile_name == "" ? null : var.instance_profile_name
  key_name             = var.key_name == "" ? null : var.key_name

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url    = var.repository_url
    repository_branch = var.repository_branch
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name = "docker-projekti-lab"
  }
}
