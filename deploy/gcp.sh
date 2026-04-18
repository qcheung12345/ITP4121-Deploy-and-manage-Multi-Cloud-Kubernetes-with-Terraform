#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/.."
K8S_DIR="$SCRIPT_DIR/../flask/k8s"

echo "=============================================="
echo "  Deploying GCP (GKE + Kubernetes Website + Database)"
echo "=============================================="
echo ""

cd "$TF_DIR"

echo "[1/4] Terraform Init..."
terraform init -upgrade

echo ""
echo "[2/4] Terraform Apply..."
terraform apply -auto-approve \
  -var="enable_gcp=true" \
  -var="enable_azure=false" \
  -var="enable_k8s_secrets=false"

echo ""
echo "[3/4] Terraform Outputs:"
terraform output

echo ""
echo "[4/4] Configuring kubectl and deploying Kubernetes manifests..."
cluster_name="$(terraform output -raw gcp_gke_cluster_name)"
project_id="$(terraform output -raw gcp_project_id)"
region="$(terraform output -raw gcp_region)"
gcloud container clusters get-credentials "$cluster_name" --region "$region" --project "$project_id"

echo ""
echo "[5/6] Creating Kubernetes secrets via Terraform..."
terraform apply -auto-approve \
  -var="enable_gcp=true" \
  -var="enable_azure=false" \
  -var="enable_k8s_secrets=true" \
  -target=kubernetes_secret.guestbook_app_secret \
  -target=kubernetes_secret.guestbook_tls

echo ""
echo "[6/6] Deploying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/namespace.yaml"
kubectl apply -f "$K8S_DIR/config.yaml"
kubectl apply -f "$K8S_DIR/database.yaml"
kubectl apply -f "$K8S_DIR/web.yaml"

echo ""
echo "GCP deployment complete."
echo "GCP deployment complete."