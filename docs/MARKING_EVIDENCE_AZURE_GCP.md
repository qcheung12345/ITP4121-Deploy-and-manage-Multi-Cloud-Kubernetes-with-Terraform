# Marking Evidence (Azure + GCP Scope)

This checklist maps the current implementation to an Azure + GCP deployment scope.

## Scoring Matrix

| Item | Status | Evidence | Notes |
|---|---|---|---|
| Multi-Cloud (2 providers) | Implemented | AKS module + root wiring; GKE module + root wiring | Two-cloud architecture is complete. |
| Private networking | Implemented | Azure VNet/subnets; GCP VPC/subnets | Both providers have isolated network resources. |
| Unique App with DB | Implemented | Flask app + PostgreSQL stack | App and DB integration is present. |
| Cluster AutoScaler | Implemented | AKS node autoscaling; GKE node autoscaling | Matches autoscaling intent. |
| Kubernetes Secret | Implemented | App and DB secrets in manifests/Terraform | Sensitive config stored as secrets. |
| L7 Ingress | Implemented | Ingress manifest and cloud ingress path | External app routing is configured. |
| SSL/TLS | Implemented | Self-signed TLS resources and secret wiring | HTTPS-ready configuration exists. |
| Cloud Logging | Implemented | Azure monitoring + GCP logging integration | Cloud-native observability path is present. |
| Global HA | Partial | Dual-cloud deployment pattern exists | Can be extended with global traffic manager if required. |

## Evidence Pointers
- Root wiring: main.tf, variables.tf, outputs.tf
- Azure stack: modules/azure, terraform/azure
- GCP stack: modules/gcp, terraform/gcp
- Deployment scripts: deploy/all setup.sh, deploy/azure.sh, deploy/gcp.sh
- App and manifests: website/app, website/k8s

## Remaining High-Impact Improvements
1. Add explicit global traffic management service for cross-region failover.
2. Add stronger production secret-management integration.
3. Add persistent storage hardening and backup policy for database workloads.
