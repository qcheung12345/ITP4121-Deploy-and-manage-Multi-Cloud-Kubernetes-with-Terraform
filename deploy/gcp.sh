#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/gcp"
K8S_DIR="$SCRIPT_DIR/../flask/k8s"

# Default region and zone (can be overridden via command line)
GCP_REGION="${1:-us-central1}"
GCP_ZONE="${2:-us-central1-a}"

echo "=============================================="
echo "  Deploying GCP (GKE + Kubernetes Website + Database)"
echo "=============================================="
echo "Region: $GCP_REGION"
echo "Zone: $GCP_ZONE"
echo ""

cd "$TF_DIR"

# Get GCP project ID from gcloud config
gcp_project_id="$(gcloud config get-value project 2>/dev/null | tr -d '\n')"
if [ -z "$gcp_project_id" ]; then
  echo "Error: GCP project not set. Run 'gcloud config set project YOUR_PROJECT_ID'"
  exit 1
fi

echo "[1/5] Terraform Init..."
terraform init -upgrade

gcp_network_name="itp4121-multicloud-k8s-gcp-vpc"
gcp_subnet_name="itp4121-multicloud-k8s-gcp-subnet"
gcp_subnet_secondary_name="${gcp_network_name}-secondary"

if gcloud compute networks describe "$gcp_network_name" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_network.this >/dev/null 2>&1; then
    echo "Importing existing GCP VPC into Terraform state: $gcp_network_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_network.this \
      "projects/$gcp_project_id/global/networks/$gcp_network_name" >/dev/null 2>&1 || true
  fi
fi

if gcloud compute networks subnets describe "$gcp_subnet_name" --region "$GCP_REGION" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_subnetwork.this >/dev/null 2>&1; then
    echo "Importing existing GCP subnet into Terraform state: $gcp_subnet_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_subnetwork.this \
      "projects/$gcp_project_id/regions/$GCP_REGION/subnetworks/$gcp_subnet_name" >/dev/null 2>&1 || true
  fi
fi

if gcloud compute networks subnets describe "$gcp_subnet_secondary_name" --region "$GCP_REGION" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_subnetwork.secondary >/dev/null 2>&1; then
    echo "Importing existing GCP secondary subnet into Terraform state: $gcp_subnet_secondary_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_subnetwork.secondary \
      "projects/$gcp_project_id/regions/$GCP_REGION/subnetworks/$gcp_subnet_secondary_name" >/dev/null 2>&1 || true
  fi
fi

# Use currently logged-in gcloud account for Terraform Google provider.
gcp_access_token="$(gcloud auth print-access-token)"

echo ""
echo "[2/5] Terraform Apply..."
terraform apply -auto-approve \
  -var="gcp_access_token=$gcp_access_token" \
  -var="enable_k8s_secrets=false" \
  -var="gcp_enable_managed_postgres=true" \
  -var="gcp_project_id=$gcp_project_id" \
  -var="gcp_region=$GCP_REGION" \
  -var="gcp_zone=$GCP_ZONE" \
  -var="gcp_machine_type=e2-small" \
  -var="gcp_node_count=1"

echo ""
echo "[3/5] Terraform Outputs:"
terraform output

echo ""
echo "[4/5] Configuring kubectl..."
cluster_name="$(terraform output -raw gcp_gke_cluster_name)"
project_id="$(terraform output -raw gcp_project_id)"
gcloud container clusters get-credentials "$cluster_name" --zone "$GCP_ZONE" --project "$project_id"

echo ""
echo "Ensuring namespace exists before creating Kubernetes secrets..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo ""
echo "[5/5] Creating Kubernetes secrets via Terraform..."
terraform apply -auto-approve \
  -var="gcp_access_token=$gcp_access_token" \
  -var="enable_k8s_secrets=true" \
  -var="gcp_enable_managed_postgres=true" \
  -var="gcp_project_id=$gcp_project_id" \
  -var="gcp_region=$GCP_REGION" \
  -var="gcp_zone=$GCP_ZONE" \
  -var="gcp_machine_type=e2-small" \
  -var="gcp_node_count=1"

echo ""
echo "Deploying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/config.yaml"
kubectl apply -f "$K8S_DIR/database.yaml"
kubectl apply -f "$K8S_DIR/web.yaml"

echo ""
echo "GCP deployment complete."