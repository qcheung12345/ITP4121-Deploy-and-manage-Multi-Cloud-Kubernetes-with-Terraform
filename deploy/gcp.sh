#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/gcp"
K8S_DIR="$SCRIPT_DIR/../website/k8s"

# Default region and zone (can be overridden via command line)
GCP_REGION="${1:-us-central1}"
GCP_ZONE="${2:-us-central1-a}"

echo "=============================================="
echo "  Deploying GCP (GKE + Kubernetes Website + Database)"
echo "=============================================="
echo "Region: $GCP_REGION"
echo "Zone: $GCP_ZONE"
echo ""

cd "$TF_DIR"

# Get GCP project ID from gcloud config
gcp_project_id="$(gcloud config get-value project 2>/dev/null | tr -d '\n')"
if [ -z "$gcp_project_id" ]; then
  echo "Error: GCP project not set. Run 'gcloud config set project YOUR_PROJECT_ID'"
  exit 1
fi

echo "[1/5] Terraform Init..."
terraform init -upgrade

# Use currently logged-in gcloud account for Terraform Google provider.
gcp_access_token="$(gcloud auth print-access-token)"

existing_gcp_network_name="$(terraform output -raw gcp_network_name 2>/dev/null || true)"
cloud_gcp_network_name="$(gcloud compute networks list --project "$gcp_project_id" --format='value(name)' 2>/dev/null | grep -E -- '-gcp-vpc$' | head -n1 || true)"
if [ -n "$cloud_gcp_network_name" ]; then
  existing_gcp_network_name="$cloud_gcp_network_name"
fi

if [ -n "$existing_gcp_network_name" ] && [ "$existing_gcp_network_name" != "null" ]; then
  gcp_project_name="${existing_gcp_network_name%-gcp-vpc}"
else
  gcp_project_name="itp4121-multicloud-k8s-gcp"
fi

gcp_network_name="${gcp_project_name}-gcp-vpc"
gcp_subnet_name="${gcp_project_name}-gcp-subnet"
gcp_subnet_secondary_name="${gcp_network_name}-secondary"

cloud_gke_cluster_line="$(gcloud container clusters list --project "$gcp_project_id" --format='value(name,location)' 2>/dev/null | grep -E -- '-gk(e)?[[:space:]]' | head -n1 || true)"
if [ -n "$cloud_gke_cluster_line" ]; then
  gcp_cluster_name="$(echo "$cloud_gke_cluster_line" | awk '{print $1}')"
  gcp_cluster_location="$(echo "$cloud_gke_cluster_line" | awk '{print $2}')"
else
  gcp_cluster_name="$(printf '%s-gke' "$gcp_project_name" | tr '_' '-' | cut -c1-40)"
  gcp_cluster_location="$GCP_ZONE"
fi

cloud_sql_instance_name="$(gcloud sql instances list --project "$gcp_project_id" --format='value(name)' 2>/dev/null | grep -E -- '-pg$' | head -n1 || true)"
if [ -n "$cloud_sql_instance_name" ]; then
  gcp_sql_instance_name="$cloud_sql_instance_name"
else
  gcp_sql_instance_name="$(printf '%s-pg' "$gcp_project_name" | tr '_' '-' | cut -c1-62)"
fi

gcp_sql_database_name="app_db"
gcp_sql_user_name="app_user"

if gcloud compute networks describe "$gcp_network_name" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_network.this >/dev/null 2>&1; then
    echo "Importing existing GCP VPC into Terraform state: $gcp_network_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_enable_managed_postgres=true" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_network.this \
      "projects/$gcp_project_id/global/networks/$gcp_network_name"
  fi
fi

if gcloud compute networks subnets describe "$gcp_subnet_name" --region "$GCP_REGION" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_subnetwork.this >/dev/null 2>&1; then
    echo "Importing existing GCP subnet into Terraform state: $gcp_subnet_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_enable_managed_postgres=true" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_subnetwork.this \
      "projects/$gcp_project_id/regions/$GCP_REGION/subnetworks/$gcp_subnet_name"
  fi
fi

if gcloud compute networks subnets describe "$gcp_subnet_secondary_name" --region "$GCP_REGION" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_compute_subnetwork.secondary >/dev/null 2>&1; then
    echo "Importing existing GCP secondary subnet into Terraform state: $gcp_subnet_secondary_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_enable_managed_postgres=true" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_compute_subnetwork.secondary \
      "projects/$gcp_project_id/regions/$GCP_REGION/subnetworks/$gcp_subnet_secondary_name"
  fi
fi

if gcloud container clusters describe "$gcp_cluster_name" --location "$gcp_cluster_location" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_container_cluster.this >/dev/null 2>&1; then
    echo "Importing existing GKE cluster into Terraform state: $gcp_cluster_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_container_cluster.this \
      "projects/$gcp_project_id/locations/$gcp_cluster_location/clusters/$gcp_cluster_name"
  fi
fi

if gcloud container node-pools describe primary-node-pool --cluster "$gcp_cluster_name" --location "$gcp_cluster_location" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_container_node_pool.primary >/dev/null 2>&1; then
    echo "Importing existing GKE node pool into Terraform state: primary-node-pool"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_container_node_pool.primary \
      "projects/$gcp_project_id/locations/$gcp_cluster_location/clusters/$gcp_cluster_name/nodePools/primary-node-pool"
  fi
fi

if gcloud sql instances describe "$gcp_sql_instance_name" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_sql_database_instance.postgres[0] >/dev/null 2>&1; then
    echo "Importing existing Cloud SQL instance into Terraform state: $gcp_sql_instance_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_enable_managed_postgres=true" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_sql_database_instance.postgres[0] \
      "$gcp_sql_instance_name"
  fi
fi

if gcloud sql databases describe "$gcp_sql_database_name" --instance "$gcp_sql_instance_name" --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_sql_database.app[0] >/dev/null 2>&1; then
    echo "Importing existing Cloud SQL database into Terraform state: $gcp_sql_database_name"
    terraform import \
      -var="gcp_access_token=$gcp_access_token" \
      -var="gcp_enable_managed_postgres=true" \
      -var="gcp_project_id=$gcp_project_id" \
      -var="project_name=$gcp_project_name" \
      -var="gcp_region=$GCP_REGION" \
      -var="gcp_zone=$GCP_ZONE" \
      module.gcp.google_sql_database.app[0] \
      "projects/$gcp_project_id/instances/$gcp_sql_instance_name/databases/$gcp_sql_database_name"
  fi
fi

if gcloud sql users list --instance "$gcp_sql_instance_name" --project "$gcp_project_id" --format='value(name)' 2>/dev/null | grep -Fx "$gcp_sql_user_name" >/dev/null; then
  if ! terraform state show module.gcp.google_sql_user.app[0] >/dev/null 2>&1; then
    echo "Importing existing Cloud SQL user into Terraform state: $gcp_sql_user_name"
    IMPORTED_SQL_USER=0
    for import_id in \
      "$gcp_project_id/$gcp_sql_instance_name/$gcp_sql_user_name" \
      "projects/$gcp_project_id/instances/$gcp_sql_instance_name/users/$gcp_sql_user_name" \
      "$gcp_sql_instance_name/$gcp_sql_user_name" \
      "$gcp_sql_user_name/$gcp_sql_instance_name" \
      "$gcp_sql_user_name//$gcp_sql_instance_name"
    do
      if terraform import \
        -var="gcp_access_token=$gcp_access_token" \
        -var="gcp_enable_managed_postgres=true" \
        -var="gcp_project_id=$gcp_project_id" \
        -var="project_name=$gcp_project_name" \
        -var="gcp_region=$GCP_REGION" \
        -var="gcp_zone=$GCP_ZONE" \
        module.gcp.google_sql_user.app[0] \
        "$import_id"; then
        IMPORTED_SQL_USER=1
        break
      fi
    done

    if [ "$IMPORTED_SQL_USER" -ne 1 ]; then
      echo "Warning: could not import existing Cloud SQL user '$gcp_sql_user_name'."
      echo "Terraform apply may fail if the user already exists unmanaged."
    fi
  fi
fi

if gcloud logging metrics describe pod_crash_count --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_logging_metric.pod_crash_count >/dev/null 2>&1; then
    echo "Importing existing GCP logging metric into Terraform state: pod_crash_count"
    IMPORTED_CRASH_METRIC=0
    for import_id in "projects/$gcp_project_id/metrics/pod_crash_count" "pod_crash_count"
    do
      if terraform import \
        -var="gcp_access_token=$gcp_access_token" \
        -var="gcp_enable_managed_postgres=true" \
        -var="gcp_project_id=$gcp_project_id" \
        -var="project_name=$gcp_project_name" \
        -var="gcp_region=$GCP_REGION" \
        -var="gcp_zone=$GCP_ZONE" \
        module.gcp.google_logging_metric.pod_crash_count \
        "$import_id"; then
        IMPORTED_CRASH_METRIC=1
        break
      fi
    done
    if [ "$IMPORTED_CRASH_METRIC" -ne 1 ]; then
      echo "Warning: could not import logging metric pod_crash_count."
    fi
  fi
fi

if gcloud logging metrics describe pod_restart_count --project "$gcp_project_id" >/dev/null 2>&1; then
  if ! terraform state show module.gcp.google_logging_metric.pod_restart_count >/dev/null 2>&1; then
    echo "Importing existing GCP logging metric into Terraform state: pod_restart_count"
    IMPORTED_RESTART_METRIC=0
    for import_id in "projects/$gcp_project_id/metrics/pod_restart_count" "pod_restart_count"
    do
      if terraform import \
        -var="gcp_access_token=$gcp_access_token" \
        -var="gcp_enable_managed_postgres=true" \
        -var="gcp_project_id=$gcp_project_id" \
        -var="project_name=$gcp_project_name" \
        -var="gcp_region=$GCP_REGION" \
        -var="gcp_zone=$GCP_ZONE" \
        module.gcp.google_logging_metric.pod_restart_count \
        "$import_id"; then
        IMPORTED_RESTART_METRIC=1
        break
      fi
    done
    if [ "$IMPORTED_RESTART_METRIC" -ne 1 ]; then
      echo "Warning: could not import logging metric pod_restart_count."
    fi
  fi
fi

echo ""
echo "[2/5] Terraform Apply..."
terraform apply -auto-approve \
  -var="gcp_access_token=$gcp_access_token" \
  -var="enable_k8s_secrets=false" \
  -var="gcp_enable_managed_postgres=true" \
  -var="gcp_project_id=$gcp_project_id" \
  -var="project_name=$gcp_project_name" \
  -var="gcp_region=$GCP_REGION" \
  -var="gcp_zone=$GCP_ZONE" \
  -var="gcp_machine_type=e2-small" \
  -var="gcp_node_count=1"

echo ""
echo "[3/5] Terraform Outputs:"
terraform output

echo ""
echo "[4/5] Configuring kubectl..."
cluster_name="$(terraform output -raw gcp_gke_cluster_name)"
project_id="$(terraform output -raw gcp_project_id)"
gcloud container clusters get-credentials "$cluster_name" --zone "$GCP_ZONE" --project "$project_id"

echo ""
echo "Ensuring namespace exists before creating Kubernetes secrets..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo ""
echo "[5/5] Creating Kubernetes secrets via Terraform..."
# The shared web workload pulls from Azure Container Registry, so make the same
# registry credentials available in GKE unless the caller already supplied them.
ACR_NAME="${ACR_NAME:-itp4121multicloud}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-}"
ACR_USERNAME="${ACR_USERNAME:-}"
ACR_PASSWORD="${ACR_PASSWORD:-}"

if [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ]; then
  if command -v az >/dev/null 2>&1 && az account show >/dev/null 2>&1; then
    az acr update -n "$ACR_NAME" --admin-enabled true >/dev/null
    ACR_LOGIN_SERVER="$(az acr show -n "$ACR_NAME" --query loginServer -o tsv)"
    ACR_USERNAME="$(az acr credential show -n "$ACR_NAME" --query username -o tsv)"
    ACR_PASSWORD="$(az acr credential show -n "$ACR_NAME" --query passwords[0].value -o tsv)"
  fi
fi

if [ -n "$ACR_LOGIN_SERVER" ] && [ -n "$ACR_USERNAME" ] && [ -n "$ACR_PASSWORD" ]; then
  kubectl create secret docker-registry acr-auth \
    --docker-server="$ACR_LOGIN_SERVER" \
    --docker-username="$ACR_USERNAME" \
    --docker-password="$ACR_PASSWORD" \
    -n guestbook --dry-run=client -o yaml | kubectl apply -f -
else
  echo "Error: acr-auth secret not created. Set ACR_LOGIN_SERVER, ACR_USERNAME, and ACR_PASSWORD or sign in with az so GKE can pull the shared image." >&2
  exit 1
fi

# Import an existing ingress if the previous deployment already created it.
if kubectl get ingress guestbook-web -n guestbook >/dev/null 2>&1; then
  if ! terraform state show module.gcp.kubernetes_ingress_v1.guestbook_web[0] >/dev/null 2>&1; then
    echo "Importing existing GCP ingress into Terraform state: guestbook-web"
    IMPORTED_INGRESS=0
    for import_id in \
      "guestbook/guestbook-web" \
      "guestbook-web/guestbook" \
      "guestbook-web"
    do
      if terraform import \
        -var="gcp_access_token=$gcp_access_token" \
        -var="gcp_enable_managed_postgres=true" \
        -var="gcp_project_id=$gcp_project_id" \
        -var="project_name=$gcp_project_name" \
        -var="gcp_region=$GCP_REGION" \
        -var="gcp_zone=$GCP_ZONE" \
        -var="enable_k8s_secrets=true" \
        module.gcp.kubernetes_ingress_v1.guestbook_web[0] \
        "$import_id"; then
        IMPORTED_INGRESS=1
        break
      fi
    done
    if [ "$IMPORTED_INGRESS" -ne 1 ]; then
      echo "Warning: could not import existing GCP ingress guestbook-web."
      echo "Terraform apply may fail if the ingress already exists unmanaged."
    fi
  fi
fi

# Remove pre-existing secrets so Terraform can manage them cleanly.
kubectl -n guestbook delete secret guestbook-app-secret --ignore-not-found >/dev/null 2>&1 || true
kubectl -n guestbook delete secret guestbook-tls --ignore-not-found >/dev/null 2>&1 || true

terraform apply -auto-approve \
  -var="gcp_access_token=$gcp_access_token" \
  -var="enable_k8s_secrets=true" \
  -var="gcp_enable_managed_postgres=true" \
  -var="gcp_project_id=$gcp_project_id" \
  -var="project_name=$gcp_project_name" \
  -var="gcp_region=$GCP_REGION" \
  -var="gcp_zone=$GCP_ZONE" \
  -var="gcp_machine_type=e2-small" \
  -var="gcp_node_count=1"

echo ""
echo "Deploying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/config.yaml"
kubectl apply -f "$K8S_DIR/database.yaml"
kubectl apply -f "$K8S_DIR/web.yaml"

echo ""
echo "GCP deployment complete."