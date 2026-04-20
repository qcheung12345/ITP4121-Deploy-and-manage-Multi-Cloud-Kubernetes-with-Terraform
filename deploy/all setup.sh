#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../.deploy-logs"
mkdir -p "$LOG_DIR"

echo "############################################"
echo "#   ITP4121 Multi-Cloud Deploy All         #"
echo "#   Azure (AKS) + GCP (GKE)               #"
echo "#   Running 2 platforms in PARALLEL        #"
echo "############################################"
echo ""
echo "Started at: $(date)"
echo "Logs: $LOG_DIR"
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

echo "Finished at: $(date)"

if [ $AZURE_EXIT -ne 0 ] || [ $GCP_EXIT -ne 0 ]; then
    exit 1
fi
exit 0