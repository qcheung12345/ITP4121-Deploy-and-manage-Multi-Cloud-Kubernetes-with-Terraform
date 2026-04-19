# CloudWatch Logging for AWS EKS
# Part of 55-mark ITP4121 assignment: Cloud Logging (5 marks)

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/eks/${local.cluster_name}/application"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

# CloudWatch Insights query group for application logs
resource "aws_cloudwatch_log_group" "eks_insights" {
  name              = "/aws/eks/${local.cluster_name}/insights"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}

# Metric filter for tracking application errors
resource "aws_cloudwatch_log_metric_filter" "application_errors" {
  name           = "${local.cluster_name}-application-errors"
  log_group_name = aws_cloudwatch_log_group.eks_application.name
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "EKS/Guestbook"
    value     = "1"
    default_value = 0
  }
}

# Alarm for high application error rate
resource "aws_cloudwatch_metric_alarm" "application_errors_alarm" {
  alarm_name          = "${local.cluster_name}-high-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationErrorCount"
  namespace           = "EKS/Guestbook"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when application error count exceeds 10 in 5 minutes"
}

# Log group for EKS cluster events
resource "aws_cloudwatch_log_group" "eks_events" {
  name              = "/aws/eks/${local.cluster_name}/events"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Cluster     = local.cluster_name
  }
}
