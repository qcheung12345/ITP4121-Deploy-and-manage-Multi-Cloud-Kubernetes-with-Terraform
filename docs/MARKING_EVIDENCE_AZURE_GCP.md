# Marking Evidence (Azure + GCP Scope)

This checklist maps the current implementation to the provided marking rubric under Azure + GCP scope (no AWS/EKS implementation).

## Scoring Matrix

| Item | Status | Evidence | Notes |
|---|---|---|---|
| Multi-Cloud | Partial | AKS module in root and Azure module; GKE module in root and GCP module | Azure + GCP implemented. EKS not implemented, so full marks depend on instructor partial-credit policy. |
| 2 Private Subnets + NAT Gateway (AWS) | Not implemented | No AWS resources/providers in Terraform root | Out of scope by choice (Azure + GCP only). |
| Unique App w/ DB | Partial to Good | Flask app + PostgreSQL app stack; optional Cloud SQL PostgreSQL in GCP module | Managed DB now supported via Cloud SQL toggle. |
| Cluster AutoScaler | Implemented | AKS node pool autoscaling min/max; GKE node pool autoscaling min/max | Matches min/max autoscaling intent. |
| Kubernetes Secret | Implemented | Terraform kubernetes_secret for DATABASE_URL and SECRET_KEY | Aligns with rubric keyword kubernetes_secret. |
| L7 Ingress | Implemented (GCP) | Ingress class changed to GCE | Cloud-native ingress on GKE path. |
| SSL/TLS | Implemented | Terraform tls_self_signed_cert + kubernetes tls secret | Aligns with rubric tls_self_signed_cert requirement. |
| Cloud Logging | Implemented | AKS Log Analytics via oms_agent; GKE logging_service/monitoring_service | Cloud logging integration present for both clouds. |
| Global HA | Not implemented | No global traffic-routing resource | Can be added with Azure Front Door or GCP Global Load Balancer. |

## Evidence Pointers

- Root providers and module wiring: main.tf
- AKS autoscaling + Log Analytics: modules/azure/main.tf
- GKE autoscaling + Cloud Logging + Cloud SQL: modules/gcp/main.tf
- Terraform Kubernetes secret + TLS cert: kubernetes.tf
- GCE ingress class + TLS secret usage: flask/k8s/ingress.yaml
- App env var injection of DATABASE_URL / SECRET_KEY: flask/k8s/web.yaml
- Additional outputs for grading proof: outputs.tf

## Estimated Score (Azure + GCP only)

- Strict interpretation (AWS-required rows are zero): around 35/55 to 40/55
- Partial-credit interpretation for Multi-Cloud with 2 clouds: around 40/55 to 45/55

## Remaining High-Impact Gaps

1. Global HA implementation (5 marks)
2. AWS-specific subnet/NAT rubric row cannot be claimed without AWS
3. Optional: use Azure Flexible Server in addition to Cloud SQL for stronger managed-DB evidence
