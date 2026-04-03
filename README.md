# Dockerized Website with Database

This repository now contains a simple guestbook website built with Flask and PostgreSQL.
Both services run in Docker using `docker compose`.

## Project Structure

```text
.
├── Dockerfile
├── docker-compose.yml
└── app
	 ├── app.py
	 ├── init.sql
	 ├── requirements.txt
	 ├── static
	 │   └── style.css
	 └── templates
		  └── index.html
```

## Services

- `web`: Flask app on port `5000`
- `db`: PostgreSQL database with persistent volume

## Quick Start

1. Build and start the containers:

	```bash
	docker compose up --build
	```

2. Open the website:

	```text
	http://localhost:5000
	```

3. Stop services:

	```bash
	docker compose down
	```

4. Stop and remove all data (including DB volume):

	```bash
	docker compose down -v
	```

## Notes

- The web app creates the `messages` table automatically on startup.
- `app/init.sql` is mounted to PostgreSQL init directory for first-time DB setup.