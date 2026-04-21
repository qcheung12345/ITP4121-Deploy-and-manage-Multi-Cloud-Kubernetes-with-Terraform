# ITP4121 作業 2 報告

## 學生資訊
- 學生姓名： [您的姓名]
- 學號： [您的學號]
- 組員： [組員姓名]

## 作業目標
本作業以 Terraform 建立多雲 Kubernetes 架構，並在 Azure 與 GCP 兩個公有雲上部署相同的 Flask 訪客留言簿應用。系統需包含資料庫、機密管理、自動擴展、雲端原生負載平衡、日誌收集，以及全球層級的流量導向機制，以滿足多雲高可用性需求。

## 專案概述
本專案使用模組化 Terraform 管理 Azure AKS、GCP GKE 與全球 DNS / 流量管理設定。應用程式為 Flask 訪客留言簿，後端使用 PostgreSQL，Kubernetes 物件包含 Namespace、ConfigMap、Secret、StatefulSet、Deployment、Service、HPA 與 Ingress。整體設計重點是讓兩個雲端環境能夠以相近的方式部署與維護，並透過全球流量管理層統一對外入口。

## 架構設計

### 多雲基礎架構
- Azure 端建立資源群組、VNet、兩個子網路與 AKS 叢集。
- GCP 端建立 VPC、兩個子網路與 GKE 叢集。
- 兩邊皆採用 Kubernetes 叢集與雲端負載平衡器，讓應用可以在不同雲端獨立運作。
- 全球入口改以 Azure Traffic Manager 統一管理，透過加權方式導向 Azure 與 GCP 兩個端點。

### 應用架構
- 前端：Flask 訪客留言簿。
- 後端：PostgreSQL。
- 命名空間：`guestbook`。
- 資料庫設定由 ConfigMap 與 Secret 提供。
- 應用容器透過環境變數連接資料庫，並支援初始化資料表。

### Kubernetes 資源
- `namespace.yaml`：建立 `guestbook` namespace。
- `config.yaml`：建立應用設定與資料庫連線資訊。
- `database.yaml`：建立 PostgreSQL Service 與 StatefulSet。
- `web.yaml`：建立 Flask Deployment、Service 與 HorizontalPodAutoscaler。
- `ingress.yaml`：建立對外 Ingress 與 TLS 設定。

## 具體實作

### Terraform 結構
專案根目錄的 Terraform 主要負責呼叫 Azure 與 GCP 子模組，並將全域設定獨立到 `terraform/global`。這樣的分層做法可以讓各雲端資源的生命週期分開管理，也方便在部署流程中逐步驗證。

### Azure 模組
Azure 模組負責建立：
- 資源群組
- Virtual Network 與子網路
- AKS 叢集與節點池
- PostgreSQL Flexible Server
- Log Analytics Workspace
- Application Insights 與監控設定
- Kubernetes 所需的資源與輸出值

AKS 節點池支援自動擴展，讓系統可依負載調整節點數量。

### GCP 模組
GCP 模組負責建立：
- VPC 與子網路
- GKE 叢集與 node pool
- Cloud SQL PostgreSQL
- Cloud Logging 與 log-based metrics
- Kubernetes 所需的資源與輸出值

GKE 端同樣支援自動擴展與監控設定，以維持與 Azure 類似的部署模式。

### 應用與資料庫整合
Flask 應用使用 `psycopg2` 連接 PostgreSQL，資料庫連線資訊透過 Kubernetes Secret 注入。PostgreSQL 以 StatefulSet 形式部署，確保資料庫服務名稱穩定，並方便應用端使用內部 DNS 存取。

## 全球流量管理
原本專案使用 Route53 進行全球 DNS 規劃，後來已改為 Azure Traffic Manager。現在的全球層包含：
- Azure Traffic Manager profile
- Azure 與 GCP 兩個 external endpoints
- Weighted routing 設定
- 一個統一的全球 FQDN

目前全球入口為 `itp4121-guestbook.trafficmanager.net`。這個入口可作為多雲應用的單一對外網址，讓流量能夠依權重分配至 Azure 與 GCP 端點。

## 部署流程
1. 使用 Azure CLI 與 gcloud 完成認證。
2. 先部署 Azure 與 GCP 兩個 Kubernetes 環境。
3. 驗證兩邊的叢集、資料庫與應用狀態。
4. 在全球層建立 Azure Traffic Manager。
5. 由全域入口統一提供對外存取。

對應腳本如下：
- `deploy/azure.sh`
- `deploy/gcp.sh`
- `deploy/global.sh`
- `deploy/all setup.sh`

## 測試與驗證
部署完成後可驗證以下項目：
- Azure AKS 與 GCP GKE 是否成功建立。
- Flask 應用是否可連線到 PostgreSQL。
- Secret、ConfigMap 與 StatefulSet 是否正常運作。
- HPA 是否能根據 CPU 使用率調整副本數。
- Ingress 與雲端負載平衡器是否成功對外提供服務。
- Azure Traffic Manager 是否可回傳全球 FQDN 並正確配置兩個 endpoint。

## 風險與限制
- 現有資料庫與 Kubernetes 資源若已存在，部署腳本需要先做 state import，否則會出現資源衝突。
- 目前全球 DNS 依賴 Azure Traffic Manager 與兩個雲端端點的可用性，若任一端點未就緒，全球配置可能需要重試。
- 若要更完整的資料保護，仍可加上 PersistentVolumeClaim 與更細緻的備份策略。

## 結論
本專案已完成 Azure 與 GCP 的多雲 Kubernetes 部署，並透過 Azure Traffic Manager 建立全球級流量入口，達成多雲高可用性的整體設計。系統同時包含 PostgreSQL StatefulSet、Kubernetes Secret、Ingress、HPA 與雲端監控整合，符合作業要求的核心項目。

---


