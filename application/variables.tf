variable "region" {
  description = "AWS region for this application stack."
  type        = string
  default     = "ap-south-1"
}

variable "env_name" {
  description = "Short env name (also used as the TF workspace, e.g. dev / prod). Must match the workspace used by the `network` root."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "lambda_memory_mb" {
  type    = number
  default = 128
}

variable "db_engine_version" {
  description = "PostgreSQL engine version. Leave as the default to let AWS pick the latest 15.x patch."
  type        = string
  default     = "15"
}

variable "ami_id" {
  description = "Override AMI; defaults to latest Amazon Linux 2 via SSM parameter."
  type        = string
  default     = ""
}
