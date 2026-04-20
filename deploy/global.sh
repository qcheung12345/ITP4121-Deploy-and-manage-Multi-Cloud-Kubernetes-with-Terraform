#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/global"

echo "=============================================="
echo "  Deploying Global DNS (Route53) - Azure+GCP"
echo "=============================================="
echo ""

DOMAIN_NAME="${DOMAIN_NAME:-example.com}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Domain: $DOMAIN_NAME"
echo ""

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
  gcloud container clusters get-credentials "$GCP_CLUSTER" --region "$GCP_REGION" --project "$GCP_PROJECT" >/dev/null 2>&1 || true
fi

GCP_IP="$(kubectl get svc guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
if [ -z "$GCP_IP" ]; then
  GCP_IP="$(kubectl get ingress guestbook-web -n guestbook -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
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
echo "[5/5] Terraform Apply (Route53 weighted DNS)..."
terraform apply -auto-approve \
  -var="aws_region=$AWS_REGION" \
  -var="domain_name=$DOMAIN_NAME" \
  -var="azure_lb_ip=$AZURE_IP" \
  -var="gcp_lb_ip=$GCP_IP" \
  -var="azure_weight=50" \
  -var="gcp_weight=50"

echo ""
echo "Global DNS deployment complete."
terraform output
