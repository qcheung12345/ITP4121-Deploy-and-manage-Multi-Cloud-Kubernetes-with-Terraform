import os

# Prevent test import from connecting to PostgreSQL at module import time.
os.environ.setdefault("AUTO_INIT_DB", "false")
os.environ.setdefault("SECRET_KEY", "test-secret")

from app.app import app as flask_app  # noqa: E402


import pytest  # noqa: E402


@pytest.fixture()
def client():
    flask_app.config.update(TESTING=True)
    with flask_app.test_client() as test_client:
        yield test_client
