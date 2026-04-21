#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/azure"
K8S_DIR="$SCRIPT_DIR/../website/k8s"

# Default region (can be overridden via command line)
AZURE_LOCATION="${1:-southafricanorth}"

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

if ! az group list --subscription "$azure_subscription_id" --query "length(@)" -o tsv >/dev/null 2>&1; then
  echo "Error: Current account cannot read resource groups in subscription $azure_subscription_id." >&2
  echo "Fix: Ask subscription owner to grant Contributor (or Owner) role, then re-login." >&2
  echo "After role grant, run: az login && az account set --subscription $azure_subscription_id" >&2
  exit 1
fi

cd "$TF_DIR"

RG_NAME_DEFAULT="itp4121-multicloud-k8s-azure-rg"
RG_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT"
VNET_NAME_DEFAULT="itp4121-multicloud-k8s-azure-vnet"
VNET_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_DEFAULT"
SUBNET_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_DEFAULT/subnets/itp4121-multicloud-k8s-azure-aks-subnet"
SUBNET2_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.Network/virtualNetworks/$VNET_NAME_DEFAULT/subnets/itp4121-multicloud-k8s-azure-aks-subnet-2"
LA_NAME_DEFAULT="itp4121-multicloud-k8s-la"
LA_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.OperationalInsights/workspaces/$LA_NAME_DEFAULT"
AI_NAME_DEFAULT="itp4121-multicloud-k8s-azure-aks-appinsights"
AI_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.Insights/components/$AI_NAME_DEFAULT"
AKS_NAME_DEFAULT="itp4121-multicloud-k8s-azure-aks"
AKS_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.ContainerService/managedClusters/$AKS_NAME_DEFAULT"
AKS_SECONDARY_POOL_ID="$AKS_ID/agentPools/secondary"
PG_NAME_DEFAULT="itp4121-multicloud-k8s-pg"
PG_ID="/subscriptions/$azure_subscription_id/resourceGroups/$RG_NAME_DEFAULT/providers/Microsoft.DBforPostgreSQL/flexibleServers/$PG_NAME_DEFAULT"
PG_DB_ID="$PG_ID/databases/app_db"
PG_FW_ID="$PG_ID/firewallRules/allow-all"

terraform_vars=(
  -var="azure_subscription_id=$azure_subscription_id"
  -var="azure_location=$AZURE_LOCATION"
  -var="enable_azure_k8s_resources=false"
)

terraform_import_vars=(
  -var="azure_subscription_id=$azure_subscription_id"
)

import_if_exists() {
  local resource_addr="$1"
  local resource_id="$2"
  local check_cmd="$3"

  if eval "$check_cmd" >/dev/null 2>&1; then
    if ! terraform state show "$resource_addr" >/dev/null 2>&1; then
      echo "Importing existing resource into Terraform state: $resource_addr"
      terraform import "${terraform_import_vars[@]}" "$resource_addr" "$resource_id"
    fi
  fi
}

echo "[1/5] Terraform Init..."
terraform init -upgrade

if az group show --name "$RG_NAME_DEFAULT" >/dev/null 2>&1; then
  if ! terraform state show module.azure.azurerm_resource_group.this >/dev/null 2>&1; then
    echo "Importing existing Azure resource group into Terraform state: $RG_NAME_DEFAULT"
    terraform import "${terraform_import_vars[@]}" module.azure.azurerm_resource_group.this "$RG_ID"
  fi
fi

import_if_exists \
  "module.azure.azurerm_virtual_network.this" \
  "$VNET_ID" \
  "az network vnet show --resource-group '$RG_NAME_DEFAULT' --name '$VNET_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_subnet.aks" \
  "$SUBNET_ID" \
  "az network vnet subnet show --resource-group '$RG_NAME_DEFAULT' --vnet-name '$VNET_NAME_DEFAULT' --name 'itp4121-multicloud-k8s-azure-aks-subnet'"

import_if_exists \
  "module.azure.azurerm_subnet.aks_secondary" \
  "$SUBNET2_ID" \
  "az network vnet subnet show --resource-group '$RG_NAME_DEFAULT' --vnet-name '$VNET_NAME_DEFAULT' --name 'itp4121-multicloud-k8s-azure-aks-subnet-2'"

import_if_exists \
  "module.azure.azurerm_log_analytics_workspace.guestbook" \
  "$LA_ID" \
  "az monitor log-analytics workspace show --resource-group '$RG_NAME_DEFAULT' --workspace-name '$LA_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_application_insights.guestbook" \
  "$AI_ID" \
  "az monitor app-insights component show --app '$AI_NAME_DEFAULT' --resource-group '$RG_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_kubernetes_cluster.this" \
  "$AKS_ID" \
  "az aks show --resource-group '$RG_NAME_DEFAULT' --name '$AKS_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_kubernetes_cluster_node_pool.secondary" \
  "$AKS_SECONDARY_POOL_ID" \
  "az aks nodepool show --resource-group '$RG_NAME_DEFAULT' --cluster-name '$AKS_NAME_DEFAULT' --name 'secondary'"

import_if_exists \
  "module.azure.azurerm_postgresql_flexible_server.postgres[0]" \
  "$PG_ID" \
  "az postgres flexible-server show --resource-group '$RG_NAME_DEFAULT' --name '$PG_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_postgresql_flexible_server_database.app[0]" \
  "$PG_DB_ID" \
  "az postgres flexible-server db show --resource-group '$RG_NAME_DEFAULT' --server-name '$PG_NAME_DEFAULT' --database-name 'app_db'"

import_if_exists \
  "module.azure.azurerm_postgresql_flexible_server_firewall_rule.allow_all[0]" \
  "$PG_FW_ID" \
  "az postgres flexible-server firewall-rule show --resource-group '$RG_NAME_DEFAULT' --name '$PG_NAME_DEFAULT' --rule-name 'allow-all'"

import_if_exists \
  "module.azure.azurerm_monitor_diagnostic_setting.aks_diagnostics" \
  "$AKS_ID|${AKS_NAME_DEFAULT}-diagnostics" \
  "az monitor diagnostic-settings show --resource '$AKS_ID' --name '${AKS_NAME_DEFAULT}-diagnostics'"

import_if_exists \
  "module.azure.azurerm_log_analytics_saved_search.database_connectivity" \
  "$LA_ID/savedSearches/DatabaseConnectivityMonitoring" \
  "az monitor log-analytics workspace show --resource-group '$RG_NAME_DEFAULT' --workspace-name '$LA_NAME_DEFAULT'"

import_if_exists \
  "module.azure.azurerm_log_analytics_saved_search.pod_events" \
  "$LA_ID/savedSearches/PodEventTracking" \
  "az monitor log-analytics workspace show --resource-group '$RG_NAME_DEFAULT' --workspace-name '$LA_NAME_DEFAULT'"

echo ""
echo "[2/5] Terraform Apply..."
terraform apply -auto-approve "${terraform_vars[@]}"

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
acr_name="itp4121multicloud"
az acr update -n "$acr_name" --admin-enabled true >/dev/null
acr_login_server="$(az acr show -n "$acr_name" --query loginServer -o tsv)"
acr_username="$(az acr credential show -n "$acr_name" --query username -o tsv)"
acr_password="$(az acr credential show -n "$acr_name" --query passwords[0].value -o tsv)"

kubectl create secret docker-registry acr-auth \
  --docker-server="$acr_login_server" \
  --docker-username="$acr_username" \
  --docker-password="$acr_password" \
  -n guestbook --dry-run=client -o yaml | kubectl apply -f -

db_user="$(terraform output -raw azure_database_user)"
db_pass="$(terraform output -raw azure_database_password)"

kubectl create secret generic guestbook-app-secret \
  --from-literal=SECRET_KEY="change-me-before-prod" \
  -n guestbook --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic guestbook-db-secret \
  --from-literal=DATABASE_USER="$db_user" \
  --from-literal=DATABASE_PASSWORD="$db_pass" \
  -n guestbook --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$K8S_DIR/web.yaml"

echo ""
echo "[5/5] Capturing Azure website endpoint..."
terraform apply -refresh-only -auto-approve

echo ""
echo "Azure website capture outputs:"
terraform output

echo ""
echo "Azure deployment complete."