#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/global"

echo "=============================================="
echo "  Deploying Global DNS (Azure Traffic Manager) - Azure+GCP"
echo "=============================================="
echo ""

AZURE_LOCATION="${AZURE_LOCATION:-eastus}"
AZURE_RESOURCE_GROUP_NAME="${AZURE_RESOURCE_GROUP_NAME:-itp4121-global-dns-rg}"
TM_PROFILE_NAME="${TM_PROFILE_NAME:-itp4121-guestbook-tm}"
TM_DNS_NAME="${TM_DNS_NAME:-itp4121-guestbook}"
GCP_ZONE="${GCP_ZONE:-us-central1-a}"

echo "Azure location: $AZURE_LOCATION"
echo "Traffic Manager profile: $TM_PROFILE_NAME"
echo "Traffic Manager DNS label: $TM_DNS_NAME"
echo "GCP zone: $GCP_ZONE"
echo ""

if ! command -v az >/dev/null 2>&1; then
  echo "ERROR: Azure CLI (az) is not installed." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "ERROR: Not logged in to Azure CLI. Run: az login" >&2
  exit 1
fi

AZURE_SUBSCRIPTION_ID="$(az account show --query id -o tsv 2>/dev/null || true)"
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
  echo "ERROR: Could not determine Azure subscription ID from az CLI context." >&2
  exit 1
fi

echo "[1/5] Refreshing Azure state and reading endpoint..."
(cd "$SCRIPT_DIR/../terraform/azure" && terraform apply -refresh-only -auto-approve >/dev/null 2>&1 || true)
AZURE_URL="$(cd "$SCRIPT_DIR/../terraform/azure" && terraform output -raw flask_app_url 2>/dev/null || echo "pending")"
AZURE_ENDPOINT="${AZURE_URL#http://}"
AZURE_IP=""

if echo "$AZURE_ENDPOINT" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
  AZURE_IP="$AZURE_ENDPOINT"
else
  AZURE_IP="$(getent ahostsv4 "$AZURE_ENDPOINT" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
fi

echo "      Azure IP: $AZURE_IP"

echo ""
echo "[2/5] Reading GCP cluster details from Terraform outputs..."
GCP_REGION="$(cd "$SCRIPT_DIR/../terraform/gcp" && terraform output -raw gcp_region 2>/dev/null || echo "")"
GCP_CLUSTER="$(cd "$SCRIPT_DIR/../terraform/gcp" && terraform output -raw gcp_gke_cluster_name 2>/dev/null || echo "")"
GCP_PROJECT="$(cd "$SCRIPT_DIR/../terraform/gcp" && terraform output -raw gcp_project_id 2>/dev/null || echo "")"

echo ""
echo "[3/5] Capturing GCP guestbook load balancer IP..."
if [ -n "$GCP_REGION" ] && [ -n "$GCP_CLUSTER" ] && [ -n "$GCP_PROJECT" ]; then
  export USE_GKE_GCLOUD_AUTH_PLUGIN=True
  if ! gcloud container clusters get-credentials "$GCP_CLUSTER" --zone "$GCP_ZONE" --project "$GCP_PROJECT" >/dev/null 2>&1; then
    echo "ERROR: failed to load GKE credentials for $GCP_CLUSTER" >&2
    exit 1
  fi
fi

GCP_IP="$(kubectl get svc guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [ -z "$GCP_IP" ]; then
  GCP_IP="$(kubectl get svc guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
fi
if [ -z "$GCP_IP" ]; then
  GCP_IP="$(kubectl get ingress guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
fi
if [ -z "$GCP_IP" ]; then
  GCP_IP="$(kubectl get ingress guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
fi
echo "      GCP IP:   $GCP_IP"

if [ -z "$AZURE_IP" ] || [ -z "$GCP_IP" ] || echo "$AZURE_IP $GCP_IP" | grep -qi "pending"; then
  echo ""
  echo "ERROR: endpoint not ready. Wait 1-2 minutes and retry." >&2
  exit 1
fi

cd "$TF_DIR"

echo ""
echo "[4/5] Terraform Init..."
terraform init -upgrade

echo ""
echo "[5/5] Terraform Apply (Traffic Manager weighted DNS)..."
terraform apply -auto-approve \
  -var="azure_subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var="azure_location=$AZURE_LOCATION" \
  -var="azure_resource_group_name=$AZURE_RESOURCE_GROUP_NAME" \
  -var="traffic_manager_profile_name=$TM_PROFILE_NAME" \
  -var="traffic_manager_dns_relative_name=$TM_DNS_NAME" \
  -var="azure_lb_ip=$AZURE_IP" \
  -var="gcp_lb_ip=$GCP_IP" \
  -var="azure_weight=50" \
  -var="gcp_weight=50"

echo ""
echo "Global DNS deployment complete."
terraform output
