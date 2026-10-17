variable "aws_region" {
  description = "AWS region where the example stack will be created."
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 size for running the web, API, proxy, and PostgreSQL containers."
  type        = string
  default     = "t3.small"
}

variable "repository_url" {
  description = "HTTPS Git URL for this repository. The repository must be publicly cloneable."
  type        = string
}

variable "repository_branch" {
  description = "Branch that cloud-init will clone when the instance is first created."
  type        = string
  default     = "main"
}
