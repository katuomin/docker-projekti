variable "project_id" {
  description = "Google Cloud project where the instance is created."
  type        = string
}

variable "region" {
  description = "Region for the instance."
  type        = string
  default     = "europe-north1"
}

# e2-micro in europe-north1 is free of charge (Always Free tier).
variable "machine_type" {
  description = "VM machine type."
  type        = string
  default     = "e2-micro"
}

variable "repository_url" {
  description = "HTTPS Git URL of this repository. It must be publicly cloneable."
  type        = string
  default     = "https://github.com/katuomin/docker-projekti.git"
}

variable "repository_branch" {
  description = "Branch that the startup script clones on first boot."
  type        = string
  default     = "main"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach ports 80, 3000 and 22. Use your own IP/32 if you can."
  type        = string
  default     = "0.0.0.0/0"
}
