# Dockerized Website with Database

This repository now contains a simple guestbook website built with Flask and PostgreSQL.
Both services run in Docker using `docker compose`.

## Structure

```text
flask/
├── app/
│   ├── app.py                  # 主應用文件
│   ├── requirements.txt        # Python 依賴
│   ├── init.sql                # 資料庫初始化
│   ├── static/
│   │   └── style.css           # 頁面樣式
│   └── templates/
│       ├── index.html          # 主頁面
│       ├── add_comment.html    # 新增留言頁
│       └── data.html           # 資料頁
├── k8s/                        # Kubernetes manifests
├── Dockerfile                  # Docker 設定
├── docker-compose.yml          # 多容器啟動設定
└── README.md                   # 說明文檔
```

## Services

- `web`: Flask app on port `5000`
- `db`: PostgreSQL database with persistent volume

## Authentication

- The website now includes user registration, login, and sign out.
- User credentials are stored in a new `users` table with hashed passwords.
- Comments created after login are linked to the user account.
- `SECRET_KEY` is required for Flask session security.

## Quick Start

1. Build and start the containers:

	```bash
	cd flask
	docker compose up --build
	```

2. Open the website:

	```text
	http://localhost:5000
	```

3. Stop services:

	```bash
	cd flask
	docker compose down
	```

4. Stop and remove all data (including DB volume):

	```bash
	cd flask
	docker compose down -v
	```

## Notes

- The web app creates `users`, `messages`, and `reactions` tables automatically on startup.
- `app/init.sql` is mounted to PostgreSQL init directory for first-time DB setup.

## Kubernetes Deployment

The `k8s/` folder contains a deployable baseline for a Kubernetes setup:

- `namespace.yaml` creates an isolated namespace.
- `config.yaml` holds non-sensitive settings and secrets for app session + DB connection.
- `database.yaml` deploys PostgreSQL as a StatefulSet with persistent storage.
- `web.yaml` deploys the Flask app with readiness, liveness, and HPA.
- `ingress.yaml` exposes the app through a Kubernetes ingress endpoint for the configured domain.

### Auth-aligned configuration notes

- The login/register/sign-out flow depends on Flask session cookies, so `SECRET_KEY` must be set in `guestbook-app-secret`.
- `DATABASE_URL` is now the primary DB connection input for the web app. Keep it consistent with your actual target DB.
- For local baseline in this repo, `DATABASE_URL` points to in-cluster `postgres` service.
- For production, prefer an external managed PostgreSQL service by replacing `DATABASE_URL` with your endpoint and credentials.
- Keep `AUTO_INIT_DB=true` only if the app is allowed to auto-create tables at startup; otherwise set it to `false` and run migrations separately.
- Set your own production domain in the ingress host rules and ensure the selected ingress controller is installed in the cluster.
- For HTTPS, configure your certificate issuer and DNS record to point to the provisioned ingress endpoint.

### Kubernetes security recommendations (minimum)

- Replace placeholder secrets before deploy and rotate them regularly.
- Store secrets in a secret manager (for example Azure Key Vault or GCP Secret Manager with External Secrets) instead of plain manifest files.
- Add `ingress` HTTPS redirect and secure cookie headers at ingress/controller layer.
- Restrict who can read Kubernetes `Secret` objects with RBAC.

## Basic Auth Protection Tests

Run the minimal route/API auth tests:

```bash
cd flask
python -m pytest -q
```