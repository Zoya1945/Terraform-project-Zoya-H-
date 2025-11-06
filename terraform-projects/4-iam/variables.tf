variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "developer_users" {
  description = "List of developer users"
  type        = list(string)
  default     = ["alice", "bob", "charlie"]
}