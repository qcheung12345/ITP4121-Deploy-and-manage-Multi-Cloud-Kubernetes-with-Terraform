#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../.deploy-logs"
mkdir -p "$LOG_DIR"

echo "############################################"
echo "#   ITP4121 Multi-Cloud Deploy All         #"
echo "#   AWS (EKS) + Azure (AKS) + GCP (GKE)   #"
echo "#   Running all 3 platforms in PARALLEL    #"
echo "############################################"
echo ""
echo "Started at: $(date)"
echo "Logs: $LOG_DIR"
echo ""

# ── Stage 1: Deploy 3 clouds in parallel ──────────────────────────────────────
bash "$SCRIPT_DIR/deploy-aws.sh"   > "$LOG_DIR/aws.log"   2>&1 & AWS_PID=$!
bash "$SCRIPT_DIR/deploy-azure.sh" > "$LOG_DIR/azure.log" 2>&1 & AZURE_PID=$!
bash "$SCRIPT_DIR/deploy-gcp.sh"   > "$LOG_DIR/gcp.log"   2>&1 & GCP_PID=$!

echo ">>> AWS   deploying in background (PID $AWS_PID)   → $LOG_DIR/aws.log"
echo ">>> Azure deploying in background (PID $AZURE_PID) → $LOG_DIR/azure.log"
echo ">>> GCP   deploying in background (PID $GCP_PID)   → $LOG_DIR/gcp.log"
echo ""
echo "Live tail — press Ctrl+C anytime (deployments keep running):"
echo "  tail -f $LOG_DIR/aws.log $LOG_DIR/azure.log $LOG_DIR/gcp.log"
echo ""

# Stream all 3 logs merged to terminal
tail -f "$LOG_DIR/aws.log" "$LOG_DIR/azure.log" "$LOG_DIR/gcp.log" &
TAIL_PID=$!

wait $AWS_PID;   AWS_EXIT=$?
wait $AZURE_PID; AZURE_EXIT=$?
wait $GCP_PID;   GCP_EXIT=$?

sleep 2 && kill $TAIL_PID 2>/dev/null; wait $TAIL_PID 2>/dev/null

echo ""
echo "############################################"
echo "#   Stage 1 Summary (Clouds)               #"
echo "############################################"
[ $AWS_EXIT   -eq 0 ] && echo "  AWS   : SUCCESS" || echo "  AWS   : FAILED (see $LOG_DIR/aws.log)"
[ $AZURE_EXIT -eq 0 ] && echo "  Azure : SUCCESS" || echo "  Azure : FAILED (see $LOG_DIR/azure.log)"
[ $GCP_EXIT   -eq 0 ] && echo "  GCP   : SUCCESS" || echo "  GCP   : FAILED (see $LOG_DIR/gcp.log)"
echo ""

# ── Stage 2: Global Route53 DNS (only if all 3 clouds succeeded) ──────────────
if [ $AWS_EXIT -eq 0 ] && [ $AZURE_EXIT -eq 0 ] && [ $GCP_EXIT -eq 0 ]; then
    echo ">>> All clouds succeeded — deploying global multi-cloud DNS..."
    echo "    (GCP ingress IP may need ~3 min; will retry if 'Pending')"
    echo ""

    GLOBAL_EXIT=1
    for attempt in 1 2 3 4; do
        if bash "$SCRIPT_DIR/deploy-global.sh" > "$LOG_DIR/global.log" 2>&1; then
            GLOBAL_EXIT=0
            break
        fi
        if grep -qiE "(not ready|still Pending|endpoint not ready)" "$LOG_DIR/global.log" && [ $attempt -lt 4 ]; then
            echo ">>> Attempt $attempt: an endpoint is still Pending, waiting 60s before refresh + retry..."
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
        grep -E "^(multi_cloud_fqdn|demo_dig_command)" "$LOG_DIR/global.log" 2>/dev/null | sed 's/^/    /'
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

if [ $AWS_EXIT -ne 0 ] || [ $AZURE_EXIT -ne 0 ] || [ $GCP_EXIT -ne 0 ] || [ $GLOBAL_EXIT -ne 0 ]; then
    exit 1
fi
exit 0