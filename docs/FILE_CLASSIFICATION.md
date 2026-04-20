# File Classification

## Infrastructure as Code
- main.tf, variables.tf, outputs.tf, instance.tf
- terraform/: provider-level Terraform entrypoints (azure, gcp)
- modules/: reusable Terraform modules for azure, gcp

## Deployment Scripts
- deploy/: cloud deployment and orchestration shell scripts

## Application
- flask/: Flask app source, Docker assets, Kubernetes manifests, and tests

## Configuration Examples
- terraform.tfvars.example
- terraform.tfvars.azure-gcp.example

## Documentation and Evidence
- docs/55_MARKS_VERIFICATION.md
- docs/MARKING_EVIDENCE_AZURE_GCP.md
- docs/report.md
- LICENSE.txt

## Ignored/Generated Artifacts
- .deploy-logs/
- .terraform/
