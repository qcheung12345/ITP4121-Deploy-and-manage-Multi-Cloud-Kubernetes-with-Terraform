#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/.."

echo "=============================================="
echo "  Deploying AWS (EKS + RDS + Kubernetes)"
echo "=============================================="
echo ""

cd "$TF_DIR"

echo "[1/3] Terraform Init..."
terraform init -upgrade

echo ""
echo "[2/3] Terraform Apply..."
terraform apply -auto-approve

echo ""
echo "[3/3] Outputs:"
terraform output

echo ""
echo "AWS deployment complete."