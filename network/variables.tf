variable "region" {
  description = "AWS region for this network."
  type        = string
  default     = "ap-south-1"
}

variable "env_name" {
  description = "Short env name (also used as the TF workspace, e.g. dev / prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "Top-level CIDR for the VPC."
  type        = string
}

variable "multi_az_nat" {
  description = "Provision a NAT gateway per AZ (true) or one shared (false)."
  type        = bool
  default     = false
}

variable "az_count" {
  type    = number
  default = 2
}
