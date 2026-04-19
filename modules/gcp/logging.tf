# Google Cloud Logging for GCP GKE
# Part of 55-mark ITP4121 assignment: Cloud Logging (5 marks)

resource "google_logging_project_sink" "gke_cluster_sink" {
  name        = "gke-${var.project_id}-cluster-sink"
  destination = "logging.googleapis.com/projects/${var.project_id}/logs"

  filter = <<-EOT
    resource.type="k8s_cluster"
    resource.labels.cluster_name="${google_container_cluster.this.name}"
  EOT

  unique_writer_identity = true
}

resource "google_logging_project_sink" "gke_workload_sink" {
  name        = "gke-${var.project_id}-workload-sink"
  destination = "logging.googleapis.com/projects/${var.project_id}/logs"

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.cluster_name="${google_container_cluster.this.name}"
  EOT

  unique_writer_identity = true
}

# Logging bucket for application logs
resource "google_logging_project_bucket_config" "app_logs" {
  project        = var.project_id
  location       = var.gke_region
  bucket_id      = "guestbook-app-logs"
  retention_days = 30

  enable_analytics = true
}

# Log-based metric for pod crashes
resource "google_logging_metric" "pod_crash_count" {
  name   = "pod_crash_count"
  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${google_container_cluster.this.name}"
    jsonPayload.reason="CrashLoopBackOff"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# Log-based metric for pod restarts
resource "google_logging_metric" "pod_restart_count" {
  name   = "pod_restart_count"
  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${google_container_cluster.this.name}"
    jsonPayload.reason="Restarted"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# Create monitoring alert policy for pod crashes
resource "google_monitoring_alert_policy" "pod_crash_alert" {
  display_name = "${var.gke_cluster_name}-pod-crash-alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Pod crash rate too high"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.pod_crash_count.name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_RATE"
      }
    }
  }

  # Make the policy conditional on having notification channels defined
  notification_channels = var.enable_notifications ? var.notification_channels : []

  alert_strategy {
    auto_close = "604800s" # 7 days
  }
}
