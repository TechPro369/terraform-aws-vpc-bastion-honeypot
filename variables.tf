variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging and resource prefixes"
  type        = string
  default     = "vpc-bastion-honeypot"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to deploy into (must match number of subnets)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the bastion. RESTRICT this to your IP (e.g., 203.0.113.5/32). Default 0.0.0.0/0 is insecure and only for initial testing."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access to the bastion and private host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion and private hosts"
  type        = string
  default     = "t3.micro"
}

variable "alert_email" {
  description = "Email address subscribed to the security-alerts SNS topic. You must confirm the subscription from your inbox before alerts are delivered."
  type        = string
}
