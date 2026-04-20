from werkzeug.security import generate_password_hash


def test_add_comment_page_redirects_when_not_logged_in(client):
    response = client.get("/add-comment", follow_redirects=False)

    assert response.status_code == 302
    assert "/login" in response.headers["Location"]
    assert "next=/add-comment" in response.headers["Location"]


def test_comment_update_api_requires_login(client):
    response = client.put("/api/comments/1", json={"content": "updated"})

    assert response.status_code == 401
    assert response.get_json() == {"error": "Authentication required"}


def test_login_enables_access_to_protected_page(client, monkeypatch):
    fake_user = (
        1,
        "alice",
        generate_password_hash("password123"),
        None,
    )

    monkeypatch.setattr("app.app.fetch_user_by_username", lambda username: fake_user)

    login_response = client.post(
        "/login",
        data={"username": "alice", "password": "password123"},
        follow_redirects=False,
    )

    assert login_response.status_code == 302

    protected_response = client.get("/add-comment", follow_redirects=False)
    assert protected_response.status_code == 200
