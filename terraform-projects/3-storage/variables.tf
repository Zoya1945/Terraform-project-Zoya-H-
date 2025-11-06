variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "storage-project"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-west-2a"
}