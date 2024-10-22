variable "name" {
  type        = string
  default     = "Default"
  description = "A name for the VPC."
}

variable "region" {
  type        = string
  description = "A valid AWS region to house VPC resources."
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The CIDR range for the entire VPC."
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
  description = "A list of CIDR ranges for public subnets."
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
  description = "A list of CIDR ranges for private subnets."
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "A list of availability zones for subnet placement."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of keys and values to apply as tags to all resources that support them."
}
