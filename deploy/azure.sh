#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/azure"
K8S_DIR="$SCRIPT_DIR/../flask/k8s"

# Default region (can be overridden via command line)
AZURE_LOCATION="${1:-South Africa North (southafricanorth)}"

echo "=============================================="
echo "  Deploying Azure (AKS + Kubernetes Website + Database)"
echo "=============================================="
echo "Region: $AZURE_LOCATION"
echo ""

echo "[0/5] Checking Azure login and permissions..."
if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) is not installed." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: Not logged in to Azure CLI. Run: az login" >&2
  exit 1
fi

azure_subscription_id="$(az account show --query id -o tsv)"
azure_account_name="$(az account show --query user.name -o tsv)"
echo "Using Azure account: $azure_account_name"
echo "Using subscription: $azure_subscription_id"

# Fail fast on missing subscription-level read access to avoid Terraform 403 later.
if ! az group list --subscription "$azure_subscription_id" --query "length(@)" -o tsv >/dev/null 2>&1; then
  echo "Error: Current account cannot read resource groups in subscription $azure_subscription_id." >&2
  echo "Fix: Ask subscription owner to grant Contributor (or Owner) role, then re-login." >&2
  echo "After role grant, run: az login && az account set --subscription $azure_subscription_id" >&2
  exit 1
fi

cd "$TF_DIR"

echo "[1/5] Terraform Init..."
terraform init -upgrade

echo ""
echo "[2/5] Terraform Apply..."
terraform apply -auto-approve \
  -var="azure_location=$AZURE_LOCATION"

echo ""
echo "[3/5] Terraform Outputs:"
terraform output

echo ""
echo "[4/5] Configuring kubectl and deploying Kubernetes manifests..."
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
echo "[5/5] Capturing Azure website endpoint..."
terraform init -upgrade
terraform apply -refresh-only -auto-approve

echo ""
echo "Azure website capture outputs:"
terraform output

echo ""
echo "Azure deployment complete."