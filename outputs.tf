output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ)"
  value       = aws_subnet.private[*].id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion. SSH: ssh -i ~/.ssh/<key>.pem ec2-user@<ip>"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion (use with: aws ssm start-session --target <id>)"
  value       = aws_instance.bastion.id
}

output "private_instance_id" {
  description = "Instance ID of the private EC2"
  value       = aws_instance.private.id
}

output "private_instance_private_ip" {
  description = "Private IP of the private EC2 — SSH to it from the bastion"
  value       = aws_instance.private.private_ip
}

output "honeypot_logs_bucket" {
  description = "Name of the encrypted S3 bucket for honeypot log ingestion"
  value       = aws_s3_bucket.honeypot_logs.id
}

output "security_alerts_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "threat_detector_role_arn" {
  description = "ARN of the IAM role scaffolded for the future CloudTrail threat-detector Lambda"
  value       = aws_iam_role.threat_detector_lambda.arn
}
