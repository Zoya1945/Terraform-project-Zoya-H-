variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "monitoring-project"
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = "admin@example.com"
}