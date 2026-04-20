# ITP4121 Multi-Cloud Kubernetes Deployment Verification (Azure + GCP)

## Project Scope
This document verifies the current implementation for a two-cloud deployment using Azure and GCP with Terraform and Kubernetes.

## Summary
- Cloud providers implemented: Azure AKS, GCP GKE
- Application: Flask guestbook
- Data layer: PostgreSQL
- IaC: Terraform modular structure
- Deployment orchestration: parallel Azure + GCP scripts

## 1. Multi-Cloud Deployment
- Azure stack: modules and root stack exist and validate
- GCP stack: modules and root stack exist and validate
- Root Terraform wiring: main.tf, variables.tf, outputs.tf

## 2. Network and Private Subnets
- Azure VNet with two subnets is defined in module code
- GCP VPC with two subnetworks is defined in module code
- Outbound connectivity is handled by managed cloud networking defaults

## 3. Application and Database
- Flask guestbook is deployed with Kubernetes manifests
- PostgreSQL is deployed for app usage
- Managed PostgreSQL path is available in GCP module (Cloud SQL toggle)

## 4. Cluster and Workload Autoscaling
- AKS node pool autoscaling is configured
- GKE node pool autoscaling is configured
- Kubernetes HPA is configured for web workload

## 5. Kubernetes Secrets
- App and DB secrets are defined and applied via Kubernetes resources
- SECRET_KEY and DATABASE_URL are injected as environment variables

## 6. Ingress and L7 Exposure
- Ingress manifest exists for app routing
- Cloud-native ingress path is configured for current deployment flow

## 7. TLS
- Self-signed TLS resources are present in Terraform/Kubernetes configuration
- TLS secret wiring is present in ingress-related manifests

## 8. Logging and Monitoring
- Azure monitoring integration is present in Azure module
- GCP logging/monitoring integration is present in GCP module

## 9. Deployment Scripts
- deploy/all setup.sh orchestrates Azure + GCP in parallel
- deploy/azure.sh handles Azure provisioning and app deployment flow
- deploy/gcp.sh handles GCP provisioning and app deployment flow

## Validation Status
- Root Terraform validate: passed
- terraform/azure validate: passed
- terraform/gcp validate: passed
- deploy shell syntax checks: passed

## Notes
- This verification reflects the current two-cloud scope.
- Documentation and scripts are aligned with Azure + GCP deployment only.
