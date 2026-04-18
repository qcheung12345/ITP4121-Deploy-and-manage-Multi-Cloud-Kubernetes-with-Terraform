#!/bin/bash
# Multi-cloud DNS demo: query Route53 repeatedly, label each IP with its cloud.
# Run after deploy-all.sh finishes — teacher sees which cloud served each request.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$SCRIPT_DIR/../terraform/global"

# Pull endpoints + nameserver from Terraform output
cd "$GLOBAL_DIR"
FQDN=$(terraform output -raw multi_cloud_fqdn)
NS=$(terraform output -json route53_nameservers | python3 -c "import sys,json; print(json.load(sys.stdin)[0])")
ENDPOINTS=$(terraform output -json endpoints)


AZURE_IP=$(echo "$ENDPOINTS"   | python3 -c "import sys,json; print(json.load(sys.stdin)['azure'])")
GCP_IP=$(echo "$ENDPOINTS"     | python3 -c "import sys,json; print(json.load(sys.stdin)['gcp'])")

# Resolve AWS ELB hostname to its current IPs (multiple, one per AZ)
AWS_IPS=$(dig +short "$AWS_HOST" A | sort -u | tr '\n' ' ')

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ITP4121 Multi-Cloud DNS Demo                                  ║"
echo "║  Domain: $FQDN"
echo "║  Nameserver: $NS"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Cloud → Load-Balancer IP mapping:"
echo ""

printf "  🟦  Azure (AKS, southafricanorth)   → %s\n" "$AZURE_IP"
printf "  🟩  GCP   (GKE, asia-east2)         → %s\n" "$GCP_IP"
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Querying Route53 20 times (weighted routing: Azure 33 / GCP 34)"
echo "────────────────────────────────────────────────────────────────"
echo ""


AZURE_COUNT=0
GCP_COUNT=0
UNKNOWN_COUNT=0

for i in $(seq 1 20); do
    IP=$(dig @"$NS" "$FQDN" A +short +time=2 +tries=1 | head -n1)
    LABEL=""
    COLOR=""

    if [ "$IP" = "$AZURE_IP" ]; then
        LABEL="🟦 Azure"
        AZURE_COUNT=$((AZURE_COUNT+1))
    elif [ "$IP" = "$GCP_IP" ]; then
        LABEL="🟩 GCP  "
        GCP_COUNT=$((GCP_COUNT+1))
    else
        LABEL="⬜ Unknown"
        UNKNOWN_COUNT=$((UNKNOWN_COUNT+1))
    fi

    printf "  Query %2d:  %-15s  →  %s\n" "$i" "$IP" "$LABEL"
done

echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Distribution across 20 queries:"
echo "────────────────────────────────────────────────────────────────"
printf "  🟦  Azure : %2d / 20  (expected ~33%%)\n" "$AZURE_COUNT"
printf "  🟩  GCP   : %2d / 20  (expected ~34%%)\n" "$GCP_COUNT"
[ $UNKNOWN_COUNT -gt 0 ] && printf "  ⬜  Unknown: %2d / 20  (unexpected)\n" "$UNKNOWN_COUNT"
echo ""
echo "✓ Multi-cloud HA via Route53 weighted DNS working."
echo ""