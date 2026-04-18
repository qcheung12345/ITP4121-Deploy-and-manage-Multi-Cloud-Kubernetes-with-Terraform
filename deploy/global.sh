#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/global"

echo "=============================================="
echo "  Deploying Global Multi-Cloud DNS (Route53)"
echo "=============================================="
echo ""

# ── Refresh Azure + GCP state first ───────────────────────────────────────────
# Their outputs are frozen at last apply and may still say "Pending" even though
# the real LB IP now exists in the cloud. Refresh pulls the current value.
echo "[1/4] Refreshing Azure state (pull current Ingress IP)..."
(cd "$SCRIPT_DIR/../terraform/azure" && terraform apply -refresh-only -auto-approve >/dev/null 2>&1 || true)
AZURE_IP=$(cd "$SCRIPT_DIR/../terraform/azure" && terraform output -raw flask_app_url 2>/dev/null || echo "unknown")
echo "      Azure LB IP: $AZURE_IP"

echo ""
echo "[2/4] Refreshing GCP state (pull current Ingress IP)..."
(cd "$SCRIPT_DIR/../terraform/gcp" && terraform apply -refresh-only -auto-approve >/dev/null 2>&1 || true)
GCP_IP=$(cd "$SCRIPT_DIR/../terraform/gcp" && terraform output -raw load_balancer_ip 2>/dev/null || echo "unknown")
echo "      GCP LB IP:   $GCP_IP"

# Fail fast with a clear message if either is still pending — retry loop in
# deploy-all.sh will sleep and call this script again.
if echo "$AZURE_IP $GCP_IP" | grep -qi "pending"; then
    echo ""
    echo "ERROR: an endpoint is still Pending. Wait 1-2 min and retry." >&2
    exit 1
fi

cd "$TF_DIR"

echo ""
echo "[3/4] Terraform Init..."
terraform init -upgrade

echo ""
echo "[4/4] Terraform Apply..."
terraform apply -auto-approve

echo ""
echo "Outputs:"
terraform output

echo ""
echo "Global DNS deployment complete."
echo "Demo: run the 'demo_dig_command' output repeatedly to see weighted routing."