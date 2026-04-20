#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../.deploy-logs"
mkdir -p "$LOG_DIR"
DOMAIN_NAME="${1:-${DOMAIN_NAME:-example.com}}"

echo "############################################"
echo "#   ITP4121 Multi-Cloud Deploy All         #"
echo "#   Azure (AKS) + GCP (GKE)               #"
echo "#   Running 2 platforms in PARALLEL        #"
echo "############################################"
echo ""
echo "Started at: $(date)"
echo "Logs: $LOG_DIR"
echo "Domain: $DOMAIN_NAME"
echo ""

# ── Stage 1: Deploy 2 clouds in parallel ──────────────────────────────────────
bash "$SCRIPT_DIR/deploy-azure.sh" > "$LOG_DIR/azure.log" 2>&1 & AZURE_PID=$!
bash "$SCRIPT_DIR/gcp.sh"          > "$LOG_DIR/gcp.log"   2>&1 & GCP_PID=$!

echo ">>> Azure deploying in background (PID $AZURE_PID) → $LOG_DIR/azure.log"
echo ">>> GCP   deploying in background (PID $GCP_PID)   → $LOG_DIR/gcp.log"
echo ""
echo "Live tail — press Ctrl+C anytime (deployments keep running):"
echo "  tail -f $LOG_DIR/azure.log $LOG_DIR/gcp.log"
echo ""

# Stream both logs merged to terminal
tail -f "$LOG_DIR/azure.log" "$LOG_DIR/gcp.log" &
TAIL_PID=$!

wait $AZURE_PID; AZURE_EXIT=$?
wait $GCP_PID;   GCP_EXIT=$?

sleep 2 && kill $TAIL_PID 2>/dev/null; wait $TAIL_PID 2>/dev/null

echo ""
echo "############################################"
echo "#   Stage 1 Summary (Clouds)               #"
echo "############################################"
[ $AZURE_EXIT -eq 0 ] && echo "  Azure : SUCCESS" || echo "  Azure : FAILED (see $LOG_DIR/azure.log)"
[ $GCP_EXIT   -eq 0 ] && echo "  GCP   : SUCCESS" || echo "  GCP   : FAILED (see $LOG_DIR/gcp.log)"
echo ""

# ── Stage 2: Global Route53 DNS (only if both clouds succeeded) ──────────────
if [ $AZURE_EXIT -eq 0 ] && [ $GCP_EXIT -eq 0 ]; then
    echo ">>> Clouds succeeded — deploying global Route53 weighted DNS..."
    echo ""

    GLOBAL_EXIT=1
    for attempt in 1 2 3 4; do
        if DOMAIN_NAME="$DOMAIN_NAME" bash "$SCRIPT_DIR/global.sh" > "$LOG_DIR/global.log" 2>&1; then
            GLOBAL_EXIT=0
            break
        fi
        if grep -qiE "(not ready|pending|endpoint not ready)" "$LOG_DIR/global.log" && [ $attempt -lt 4 ]; then
            echo ">>> Attempt $attempt: endpoint still pending, waiting 60s before retry..."
            sleep 60
        else
            break
        fi
    done

    echo ""
    echo "############################################"
    echo "#   Stage 2 Summary (Global DNS)           #"
    echo "############################################"
    if [ $GLOBAL_EXIT -eq 0 ]; then
        echo "  Route53 : SUCCESS"
        grep -E "^(guestbook_global_fqdn|weighted_routing_policy|demo_dig_command)" "$LOG_DIR/global.log" 2>/dev/null | sed 's/^/    /'
    else
        echo "  Route53 : FAILED (see $LOG_DIR/global.log)"
        tail -10 "$LOG_DIR/global.log" | sed 's/^/    /'
    fi
    echo ""
else
    echo ">>> Skipping global DNS — one or more clouds failed."
    GLOBAL_EXIT=1
fi

echo "Finished at: $(date)"

if [ $AZURE_EXIT -ne 0 ] || [ $GCP_EXIT -ne 0 ] || [ $GLOBAL_EXIT -ne 0 ]; then
    exit 1
fi
exit 0