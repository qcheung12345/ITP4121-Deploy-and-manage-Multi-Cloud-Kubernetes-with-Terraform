#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AZURE_LOCATION="${1:-southafricanorth}"

# Backward-compatible wrapper: azure.sh now includes capture output flow.
bash "$SCRIPT_DIR/azure.sh" "$AZURE_LOCATION"
