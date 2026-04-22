###############################################################################
# IAM role scaffolded for a future Lambda-based CloudTrail threat detector.
#
# The Lambda itself is NOT deployed by this module. This role exists so that:
#   1) the permission boundary is auditable before the detector is built
#   2) when the Lambda is shipped, the role already has least-privilege access
#      to CloudTrail, the honeypot logs bucket, and the alert SNS topic
###############################################################################

resource "aws_iam_role" "threat_detector_lambda" {
  name = "${var.project_name}-threat-detector-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-threat-detector-lambda-role"
    Purpose = "future-cloudtrail-threat-detector"
  }
}

# Basic Lambda execution — allows CloudWatch Logs write for Lambda stdout/stderr
resource "aws_iam_role_policy_attachment" "threat_detector_basic" {
  role       = aws_iam_role.threat_detector_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Scoped inline policy — CloudTrail read, SNS publish, honeypot bucket read
resource "aws_iam_role_policy" "threat_detector_inline" {
  name = "${var.project_name}-threat-detector-policy"
  role = aws_iam_role.threat_detector_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailRead"
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:DescribeTrails"
        ]
        Resource = "*"
      },
      {
        Sid      = "PublishSecurityAlerts"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      },
      {
        Sid    = "ReadHoneypotLogs"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.honeypot_logs.arn,
          "${aws_s3_bucket.honeypot_logs.arn}/*"
        ]
      }
    ]
  })
}
