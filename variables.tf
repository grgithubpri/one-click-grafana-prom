variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "project_name" {
  type    = string
  default = "aws-monitoring"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro" # Free Tier friendly
  description = "Use t3.micro (or t2.micro where available) for Free Tier. t3.small is not Free Tier."
}

variable "ssh_public_key" {
  type        = string
  description = "Your SSH public key contents (e.g. ssh-ed25519 AAAA...)."
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type      = string
  default   = "adminadmin"
  sensitive = true
}

# Optional email notifications
variable "enable_email_contact_point" {
  type    = bool
  default = false
}

variable "alert_email_to" {
  type    = string
  default = ""
}

variable "smtp_host" {
  type    = string
  default = ""
}

variable "smtp_user" {
  type      = string
  default   = ""
  sensitive = true
}

variable "smtp_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "smtp_from_address" {
  type    = string
  default = ""
}