###############################################################################
# SNS topic for security alerts
###############################################################################

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"

  tags = {
    Name    = "${var.project_name}-security-alerts"
    Purpose = "security-notifications"
  }
}

# Email subscription — AWS will send a confirmation link to this address.
# Until you click that link, no alerts will be delivered.
resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
