#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/.."
K8S_DIR="$SCRIPT_DIR/../flask/k8s"

echo "=============================================="
echo "  Deploying Azure (AKS + Kubernetes Website + Database)"
echo "=============================================="
echo ""

cd "$TF_DIR"

echo "[1/4] Terraform Init..."
terraform init -upgrade

echo ""
echo "[2/4] Terraform Apply..."
terraform apply -auto-approve \
  -var="enable_azure=true" \
  -var="enable_gcp=false" \
  -var="enable_k8s_secrets=false"

echo ""
echo "[3/4] Terraform Outputs:"
terraform output

echo ""
echo "[4/4] Configuring kubectl and deploying Kubernetes manifests..."
rg_name="$(terraform output -raw azure_resource_group_name)"
cluster_name="$(terraform output -raw azure_aks_cluster_name)"
az aks get-credentials --resource-group "$rg_name" --name "$cluster_name" --overwrite-existing

kubectl apply -f "$K8S_DIR/namespace.yaml"
kubectl apply -f "$K8S_DIR/config.yaml"
kubectl apply -f "$K8S_DIR/database.yaml"
kubectl create secret generic guestbook-app-secret \
  --from-literal=DATABASE_URL="postgresql://app_user:change-me@postgres.guestbook.svc.cluster.local:5432/app_db" \
  --from-literal=SECRET_KEY="change-me-before-prod" \
  -n guestbook --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$K8S_DIR/web.yaml"

echo ""
echo "Azure deployment complete."