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
├── Dockerfile                  # Docker 設定
├── docker-compose.yml          # 多容器啟動設定
└── README.md                   # 說明文檔
```

## Services

- `web`: Flask app on port `5000`
- `db`: PostgreSQL database with persistent volume

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

- The web app creates the `messages` table automatically on startup.
- `app/init.sql` is mounted to PostgreSQL init directory for first-time DB setup.