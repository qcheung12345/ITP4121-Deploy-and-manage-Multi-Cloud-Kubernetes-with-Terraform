# File Classification

## Infrastructure as Code
- main.tf, variables.tf, outputs.tf, instance.tf
- terraform/: provider-level Terraform entrypoints
- modules/: reusable Terraform modules for aws, azure, gcp

## Deployment Scripts
- deploy/: cloud deployment and orchestration shell scripts
- aws/: AWS CLI installer docs/scripts used by deployment flow

## Application
- flask/: Flask app source, Docker assets, Kubernetes manifests, and tests

## Configuration Examples
- terraform.tfvars.example
- terraform.tfvars.azure-gcp.example

## Documentation and Evidence
- docs/55_MARKS_VERIFICATION.md
- docs/MARKING_EVIDENCE_AZURE_GCP.md
- docs/report.md
- docs/ITP4121 Cloud and Data Centre Workplace Practices Assignment 2.pdf
- LICENSE.txt

## Ignored/Generated Artifacts
- .deploy-logs/
- awscliv2.zip
- terraform_1.9.7_linux_amd64.zip
