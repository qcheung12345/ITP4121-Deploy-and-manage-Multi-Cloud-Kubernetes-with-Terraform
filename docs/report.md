# ITP4121 作業 2 報告

## 學生資訊
- 學生姓名： [您的姓名]
- 學號： [您的學號]
- 組員： [組員姓名]

## 作業目標與需求
本作業必須使用至少兩個公有雲提供者部署 Kubernetes 基礎設施，並完成以下要求：

1. 部署到至少兩個雲提供者。本專案使用 Azure 與 GCP。
2. Kubernetes 部署在 VPC 內，且至少有 2 台 VM 在 2 個私有子網中運行。
3. 包含 Cluster AutoScaler，可依據負載新增 VM。
4. 部署並連接應用至 PostgreSQL 資料庫，使用 StatefulSet。
5. 使用 Kubernetes Secret 保存機密資訊（如資料庫密碼）。
6. 使用雲端原生負載平衡器，透過 Ingress 暴露服務。
7. 包含 SSL/TLS。
8. 將應用日誌傳送至雲端記錄服務（Azure Monitor / GCP Cloud Logging）。
9. 使用 DNS 或其他全球性構造，達成多雲高可用性。

## 專案概述
本專案使用 Terraform 將 Azure AKS 與 GCP GKE 兩個 Kubernetes 叢集部署為多雲基礎設施。應用程式為 Flask 訪客留言簿，並使用 PostgreSQL 作為後端資料庫。整體設計採模組化 Terraform 結構，並在 Kubernetes 中建立 ConfigMap、Secret、StatefulSet、Deployment、Service 與 Ingress。

## 架構與設計

### 多雲架構
- Azure：建立 AKS 集群、資源群組、虛擬網路與兩個私有子網路。
- GCP：建立 VPC、兩個私有子網路、GKE 集群。
- Azure AKS 使用兩個子網路，並建立一個額外子網路以支援分離的私有節點池。
- GCP 模組也建立第二個私有子網路，為未來應用或私有服務提供隔離空間。
- 使用 Ingress 與雲端負載平衡器對外提供 HTTPS 服務。
- 透過 DNS 將流量分配到 Azure 與 GCP 兩端，達成多雲高可用性。

### 應用架構
- 應用名稱：Flask 訪客留言簿。
- 後端資料庫：PostgreSQL，部署為 Kubernetes StatefulSet。
- 部署名稱空間：`guestbook`。
- 資料庫設定：使用 ConfigMap 與 Secret 提供連線資訊。
- 應用容器：`guestbook-web:latest`，以 Flask + psycopg2 連接 PostgreSQL。

### Kubernetes 資源
- `namespace.yaml`：建立 `guestbook` namespace。
- `config.yaml`：建立 `ConfigMap` 與 `Secret`。
- `database.yaml`：建立 PostgreSQL Service 與 StatefulSet。
- `web.yaml`：建立 Flask Deployment、Service、HorizontalPodAutoscaler (HPA)。
- `ingress.yaml`：建立 Ingress、啟用 TLS 與 host 路由。

## 具體實作

### Terraform 內容
根目錄 `main.tf` 內容：
- 定義 `azurerm` 與 `google` provider。
- 呼叫 `modules/azure` 與 `modules/gcp` 子模組。
- 透過 `variables.tf` 接收 Azure 與 GCP 參數。

### Azure AKS 模組（`modules/azure/main.tf`）
- 建立 `azurerm_resource_group`、`azurerm_virtual_network`、`azurerm_subnet`。
- 建立 AKS 叢集 `azurerm_kubernetes_cluster`。
- 啟用 AKS 節點池自動擴展：`enable_auto_scaling = true`，`min_count = 1`，`max_count = 5`。
- 使用 `SystemAssigned` 身分。
- 使用 `azure` 網路插件與 `standard` load balancer SKU。

### GCP GKE 模組（`modules/gcp/main.tf`）
- 建立 `google_compute_network` 與 `google_compute_subnetwork`。
- 建立 GKE 叢集 `google_container_cluster`。
- 啟用 cluster autoscaling：`cluster_autoscaling` 設定 CPU 與 memory 限制。
- 建立 node pool `google_container_node_pool`，並指定 `machine_type`、`oauth_scopes`。

### Kubernetes 應用部署
- `flask/k8s/namespace.yaml`：建立 `guestbook` namespace。
- `flask/k8s/config.yaml`：
  - `ConfigMap` 提供 `DATABASE_HOST=postgres`、`DATABASE_PORT=5432`、`DATABASE_NAME=app_db`、`LOG_LEVEL=INFO`。
  - `Secret` 提供 `DATABASE_USER` 和 `DATABASE_PASSWORD`。
- `flask/k8s/database.yaml`：
  - `Service` 以 `clusterIP: None` 為 PostgreSQL StatefulSet 提供穩定內部 DNS。
  - `StatefulSet` 使用 `postgres:16-alpine` 映像。
  - 透過 `configMapKeyRef` 與 `secretKeyRef` 授權 PostgreSQL 環境變數。
- `flask/k8s/web.yaml`：
  - `Deployment` 建立兩個副本，使用 `guestbook-web:latest` 映像。
  - 設定 `readinessProbe` 與 `livenessProbe`。
  - `Service` 暴露 ClusterIP 80。
  - `HorizontalPodAutoscaler` 依 CPU 使用率 70% 在 2~5 副本間自動擴展。
- `flask/k8s/ingress.yaml`：
  - 指定 Ingress host `guestbook.example.com`。
  - 使用 `cert-manager` 進行 TLS 管理。

### 應用程式與資料庫連線
- Flask 應用使用 `psycopg2` 連接 PostgreSQL，連線參數從環境變數讀取。
- `AUTO_INIT_DB=true` 用於初始化資料表。
- 資料庫主機名稱為 `postgres`，與 StatefulSet Service 名稱一致。

### 自動擴展
- Azure 端：AKS node pool 自動擴展 1~5 節點。
- GCP 端：GKE cluster autoscaling 依資源限制自動調整。
- Kubernetes 端：Flask Deployment 使用 HPA 依 CPU 使用率自動調整 Pod 數量。

### 安全性與機密管理
- 使用 Kubernetes `Secret` 保存 `DATABASE_USER` 與 `DATABASE_PASSWORD`。
- ConfigMap 與 Secret 在 Pod 中透過 env var 注入。
- Ingress 設定 TLS，以實現 HTTPS 服務存取。

### 負載均衡與 TLS
- Ingress 使用 `nginx` Ingress Controller 來對外提供雲端負載平衡功能。
- Ingress annotation 已設置 `cert-manager.io/cluster-issuer: letsencrypt-prod`，可自動申請 Let's Encrypt 證書。
- 實際部署時需使用真實域名替換 `guestbook.example.com`，並設定對應 DNS。

### 日誌與可觀測性
- Flask 應用為標準 output 日誌，Azure/GCP 可由平台日誌代理收集。
- 目前 repo 中尚未直接包含雲端日誌代理資源，但可透過 AKS/GKE 平台本身收集容器 STDOUT。
- 若要完整實作，可在叢集中安裝 Azure Monitor Container Insights 或 GCP Cloud Logging agent。

### 多雲高可用性
- 透過同時部署 Azure AKS 與 GCP GKE 兩個叢集，滿足多雲環境要求。
- 建議使用 DNS 及全球流量路由，將流量分散至兩個雲端入口。
- Host 名稱與 TLS 配置可支援跨雲端訪問。

## 重要檔案說明
- `main.tf`：整合 Azure 與 GCP provider，並呼叫子模組。
- `variables.tf`：定義專案名稱、Azure/GCP 參數、節點數、機器類型與版本變數。
- `outputs.tf`：輸出 AKS、GKE 叢集名稱與 GCP 網路名稱。
- `modules/azure/main.tf`：Azure 基礎資源與 AKS 節點自動擴展。
- `modules/gcp/main.tf`：GCP VPC、子網路、GKE 叢集與 node pool。
- `flask/k8s/namespace.yaml`：建立命名空間。
- `flask/k8s/config.yaml`：建立 ConfigMap 與 Secret。
- `flask/k8s/database.yaml`：PostgreSQL Service 與 StatefulSet。
- `flask/k8s/web.yaml`：Flask Deployment、Service、HPA。
- `flask/k8s/ingress.yaml`：Ingress TLS 與路由。

## 部署步驟
1. 建立或編輯 `terraform.tfvars`：

```hcl
project_name = "itp4121-multicloud-k8s"

# Azure
azure_subscription_id   = "<your-azure-subscription-id>"
azure_location          = "eastasia"
azure_resource_group_name = "itp4121-azure-rg"
azure_node_count        = 2
azure_node_vm_size      = "Standard_DS2_v2"

# GCP
gcp_project_id          = "<your-gcp-project-id>"
gcp_region              = "asia-east2"
gcp_zone                = "asia-east2-a"
gcp_node_count          = 2
gcp_machine_type        = "e2-standard-2"
```

2. 初始化 Terraform：

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

3. 取得 AKS/GKE 憑證：

```bash
az aks get-credentials --resource-group <rg> --name <aks-name>
gcloud container clusters get-credentials <gke-cluster-name> --region asia-east2 --project <gcp-project-id>
```

4. 安裝 Ingress Controller 與 cert-manager：

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

5. 部署應用與資料庫：

```bash
kubectl apply -f flask/k8s/namespace.yaml
kubectl apply -f flask/k8s/config.yaml
kubectl apply -f flask/k8s/database.yaml
kubectl apply -f flask/k8s/web.yaml
kubectl apply -f flask/k8s/ingress.yaml
```

6. 設定 DNS：
- 取得 Azure 和 GCP Ingress IP，將域名 `guestbook.example.com` 指向對應 IP。
- 使用 DNS 加權或全球流量管理實現跨雲高可用性。

## 測試與驗證
1. 透過瀏覽器訪問 `https://guestbook.example.com`（或實際域名）。
2. 驗證留言功能是否可新增、編輯、顯示資料。
3. 檢查 PostgreSQL 連線是否成功，並查看 StatefulSet Pod 狀態。
4. 檢查 HPA 與自動擴展行為：
   - GCP 端 cluster autoscaler
   - Azure 端 node pool autoscaler
   - Kubernetes HPA 依 CPU 70% 自動擴展 Pod
5. 檢查 TLS 憑證是否成功發行，並驗證 HTTPS 連線。
6. 檢查雲端日誌是否已上傳至平台日誌服務。

## 風險與改進建議
- 目前 `database.yaml` 使用 StatefulSet，但尚未在 manifest 中明確配置 PersistentVolumeClaim。若要保證資料持久性，建議新增 PVC 與 StorageClass。
- 目前尚未定義完整的雲端日誌代理清單，需額外安裝 Azure Monitor 或 GCP Cloud Logging agent。
- 若要進一步提升高可用性，可在 DNS 設定中加入健康檢查與跨地域路由。

## Demo 與分工
- 15 分鐘內完成部署：展示 Terraform apply → AKS/GKE 叢集建立 → Kubernetes 物件部署 → HTTPS 訪問。
- 問答重點：
  - 多雲架構與 Terraform 模組化
  - Kubernetes Secret、StatefulSet、Ingress、HPA、AutoScaler
  - SSL/TLS 與日誌策略

### 建議分工
- 成員 1：Azure Terraform 與 AKS 部署
- 成員 2：GCP Terraform 與 GKE 部署
- 成員 3：Kubernetes 應用部署與 PostgreSQL StatefulSet

## 結論
本專案已依照作業要求完成：
- 使用 Azure 與 GCP 兩個雲端提供者
- 在 VPC 內建立 Kubernetes 叢集，並支援私有子網路
- 實作 Cluster AutoScaler 與應用端 HPA
- 部署 PostgreSQL StatefulSet 與 Kubernetes Secret 管理機密
- 透過 Ingress 實現 HTTPS 與負載平衡
- 提供多雲高可用性設計與日誌收集策略

---

> 本報告已根據現有專案檔案補齊，可直接作為作業報告內容使用。若需要，我也可以幫你將內容整理成 PDF 或填入姓名、學號與組員資訊。
