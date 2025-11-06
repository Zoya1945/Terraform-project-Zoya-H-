# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  
  tags = local.common_tags
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SNS Topic for Auto Scaling Notifications
resource "aws_sns_topic" "autoscaling" {
  name = "${var.project_name}-autoscaling"
  
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "autoscaling_email" {
  topic_arn = aws_sns_topic.autoscaling.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Auto Scaling Notifications
resource "aws_autoscaling_notification" "web_notifications" {
  group_names = [aws_autoscaling_group.web.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.autoscaling.arn
}

resource "aws_autoscaling_notification" "app_notifications" {
  group_names = [aws_autoscaling_group.app.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.autoscaling.arn
}