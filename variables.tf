variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "polished-tube-312806"
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "The machine type for VM instances"
  type        = string
  default     = "e2-small"
}

variable "ssh_username" {
  description = "Username for SSH access"
  type        = string
  default     = "admin"
}

variable "ssh_pub_key_file" {
  description = "Path to the public SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
