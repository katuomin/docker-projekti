variable "aws_region" {
  description = "Learner Lab only permits us-east-1 and us-west-2."
  type        = string
  default     = "us-east-1"
}

# Learner Lab restricts instance types to small sizes (up to roughly *.large).
variable "instance_type" {
  description = "EC2 size for the web, proxy, API and PostgreSQL containers."
  type        = string
  default     = "t3.small"
}

variable "repository_url" {
  description = "HTTPS Git URL of this repository. It must be publicly cloneable."
  type        = string
  default     = "https://github.com/katuomin/docker-projekti.git"
}

variable "repository_branch" {
  description = "Branch that cloud-init clones on first boot."
  type        = string
  default     = "main"
}

# Learner Lab pre-creates this instance profile; students cannot create IAM roles.
variable "instance_profile_name" {
  description = "Existing instance profile to attach. Set to \"\" to attach none."
  type        = string
  default     = "LabInstanceProfile"
}

# Learner Lab pre-creates a key pair called "vockey". Set to "" to skip SSH access.
variable "key_name" {
  description = "Existing EC2 key pair for SSH, or \"\" for none."
  type        = string
  default     = "vockey"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach ports 8080, 3000 and 22. Use your own IP/32 if you can."
  type        = string
  default     = "0.0.0.0/0"
}
