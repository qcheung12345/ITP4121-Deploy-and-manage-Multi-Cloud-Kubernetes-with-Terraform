import logging
import os
import time
from contextlib import closing

import psycopg2
from flask import Flask, jsonify, redirect, render_template, request, url_for

app = Flask(__name__)

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
app.logger.setLevel(os.getenv("LOG_LEVEL", "INFO").upper())


def get_connection_kwargs():
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return {"dsn": database_url}

    return {
        "host": os.getenv("DATABASE_HOST", "db"),
        "port": int(os.getenv("DATABASE_PORT", "5432")),
        "dbname": os.getenv("DATABASE_NAME", "app_db"),
        "user": os.getenv("DATABASE_USER", "app_user"),
        "password": os.getenv("DATABASE_PASSWORD", "app_password"),
        "connect_timeout": int(os.getenv("DATABASE_CONNECT_TIMEOUT", "5")),
    }


def get_connection():
    return psycopg2.connect(**get_connection_kwargs())


def fetch_messages(limit=None):
    query = """
        SELECT id, name, content, created_at
        FROM messages
        ORDER BY created_at DESC
    """
    params = ()
    if limit is not None:
        query += " LIMIT %s"
        params = (limit,)

    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchall()


def fetch_message_by_id(message_id):
    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, name, content, created_at
                FROM messages
                WHERE id = %s;
                """,
                (message_id,),
            )
            return cur.fetchone()


def fetch_reactions():
    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT likes, dislikes
                FROM reactions
                WHERE id = 1;
                """
            )
            row = cur.fetchone()
            if row:
                return {"likes": row[0], "dislikes": row[1]}
            return {"likes": 0, "dislikes": 0}


def increment_reaction(column_name):
    if column_name not in {"likes", "dislikes"}:
        raise ValueError(f"Unsupported reaction column: {column_name}")

    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(
                f"""
                UPDATE reactions
                SET {column_name} = {column_name} + 1
                WHERE id = 1
                RETURNING likes, dislikes;
                """
            )
            row = cur.fetchone()
            return {"likes": row[0], "dislikes": row[1]}


def init_db(max_retries=15, delay_seconds=2):
    """Create the app tables if they do not exist."""
    for attempt in range(1, max_retries + 1):
        try:
            with closing(get_connection()) as conn:
                with conn, conn.cursor() as cur:
                    cur.execute(
                        """
                        CREATE TABLE IF NOT EXISTS messages (
                            id SERIAL PRIMARY KEY,
                            name VARCHAR(100) NOT NULL,
                            content TEXT NOT NULL,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        );
                        """
                    )
                    cur.execute(
                        """
                        CREATE TABLE IF NOT EXISTS reactions (
                            id INTEGER PRIMARY KEY,
                            likes INTEGER NOT NULL DEFAULT 0,
                            dislikes INTEGER NOT NULL DEFAULT 0
                        );
                        """
                    )
                    cur.execute(
                        """
                        INSERT INTO reactions (id, likes, dislikes)
                        VALUES (1, 0, 0)
                        ON CONFLICT (id) DO NOTHING;
                        """
                    )
                    app.logger.info("Database schema ensured")
            return
        except psycopg2.OperationalError:
            if attempt == max_retries:
                raise
            time.sleep(delay_seconds)


def is_database_ready():
    try:
        with closing(get_connection()) as conn:
            with conn, conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.fetchone()
        return True
    except psycopg2.Error:
        app.logger.exception("Database readiness check failed")
        return False


if os.getenv("AUTO_INIT_DB", "true").lower() in {"1", "true", "yes"}:
    init_db()


@app.route("/", methods=["GET"])
def index():
    messages = fetch_messages()
    commenters = []
    seen = set()
    for msg in messages:
        name = msg[1]
        if name not in seen:
            commenters.append(name)
            seen.add(name)
        if len(commenters) == 6:
            break

    reactions = fetch_reactions()

    return render_template(
        "index.html",
        messages=messages,
        comment_count=len(messages),
        commenters=commenters,
        likes=reactions["likes"],
        dislikes=reactions["dislikes"],
    )


@app.route("/add-comment", methods=["GET"])
def add_comment_page():
    return render_template("add_comment.html")


@app.route("/add", methods=["POST"])
def add_message():
    name = request.form.get("name", "").strip()
    content = request.form.get("content", "").strip()

    if name and content:
        with closing(get_connection()) as conn:
            with conn, conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO messages (name, content) VALUES (%s, %s);",
                    (name, content),
                )

    return redirect(url_for("index"))


@app.route("/edit/<int:message_id>", methods=["GET"])
def edit_message_page(message_id):
    message = fetch_message_by_id(message_id)
    if not message:
        return redirect(url_for("data_page"))
    return render_template("edit.html", message=message)


@app.route("/update/<int:message_id>", methods=["POST"])
def update_message(message_id):
    name = request.form.get("name", "").strip()
    content = request.form.get("content", "").strip()

    if name and content:
        with closing(get_connection()) as conn:
            with conn, conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE messages
                    SET name = %s, content = %s
                    WHERE id = %s;
                    """,
                    (name, content, message_id),
                )

    return redirect(url_for("data_page"))


@app.route("/delete/<int:message_id>", methods=["POST"])
def delete_message(message_id):
    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute("DELETE FROM messages WHERE id = %s;", (message_id,))
    return redirect(url_for("data_page"))


@app.route("/data", methods=["GET"])
def data_page():
    messages = fetch_messages()
    reactions = fetch_reactions()
    return render_template("data.html", messages=messages, reactions=reactions)


@app.route("/api/comments", methods=["GET"])
def comments_api():
    messages = fetch_messages()
    payload = [
        {
            "id": row[0],
            "name": row[1],
            "content": row[2],
            "created_at": row[3].isoformat() if row[3] else None,
        }
        for row in messages
    ]
    return jsonify(payload)


@app.route("/api/comments/<int:message_id>", methods=["GET"])
def comment_detail_api(message_id):
    row = fetch_message_by_id(message_id)
    if not row:
        return jsonify({"error": "Comment not found"}), 404
    return jsonify(
        {
            "id": row[0],
            "name": row[1],
            "content": row[2],
            "created_at": row[3].isoformat() if row[3] else None,
        }
    )


@app.route("/api/comments/<int:message_id>", methods=["PUT"])
def comment_update_api(message_id):
    payload = request.get_json(silent=True) or {}
    name = str(payload.get("name", "")).strip()
    content = str(payload.get("content", "")).strip()
    if not name or not content:
        return jsonify({"error": "name and content are required"}), 400

    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(
                """
                UPDATE messages
                SET name = %s, content = %s
                WHERE id = %s
                RETURNING id, name, content, created_at;
                """,
                (name, content, message_id),
            )
            row = cur.fetchone()

    if not row:
        return jsonify({"error": "Comment not found"}), 404

    return jsonify(
        {
            "id": row[0],
            "name": row[1],
            "content": row[2],
            "created_at": row[3].isoformat() if row[3] else None,
        }
    )


@app.route("/api/comments/<int:message_id>", methods=["DELETE"])
def comment_delete_api(message_id):
    with closing(get_connection()) as conn:
        with conn, conn.cursor() as cur:
            cur.execute(
                "DELETE FROM messages WHERE id = %s RETURNING id;",
                (message_id,),
            )
            row = cur.fetchone()

    if not row:
        return jsonify({"error": "Comment not found"}), 404

    return jsonify({"deleted": True, "id": row[0]})


@app.route("/api/reactions", methods=["GET"])
def reactions_api():
    return jsonify(fetch_reactions())


@app.route("/api/reactions/<action>", methods=["POST"])
def update_reaction_api(action):
    if action == "like":
        return jsonify(increment_reaction("likes"))
    if action == "dislike":
        return jsonify(increment_reaction("dislikes"))
    return jsonify({"error": "Invalid action"}), 400


@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({"status": "ok"}), 200


@app.route("/readyz", methods=["GET"])
def readyz():
    if is_database_ready():
        return jsonify({"status": "ready"}), 200
    return jsonify({"status": "not ready"}), 503


if __name__ == "__main__":
    app.logger.info("Starting application")
    app.run(host="0.0.0.0", port=5000)
