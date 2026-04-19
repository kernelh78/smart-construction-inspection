import pytest


def test_login_success(client, admin_user):
    res = client.post(
        "/api/v1/auth/login",
        data={"username": "admin@test.com", "password": "admin123"},
    )
    assert res.status_code == 200
    body = res.json()
    assert "access_token" in body
    assert body["token_type"] == "bearer"


def test_login_wrong_password(client, admin_user):
    res = client.post(
        "/api/v1/auth/login",
        data={"username": "admin@test.com", "password": "wrongpass"},
    )
    assert res.status_code == 401


def test_login_unknown_email(client):
    res = client.post(
        "/api/v1/auth/login",
        data={"username": "nobody@test.com", "password": "pass"},
    )
    assert res.status_code == 401


def test_get_me(client, admin_user, admin_headers):
    res = client.get("/api/v1/auth/me", headers=admin_headers)
    assert res.status_code == 200
    body = res.json()
    assert body["email"] == "admin@test.com"
    assert body["role"] == "admin"


def test_get_me_without_token(client):
    res = client.get("/api/v1/auth/me")
    assert res.status_code == 401


def test_refresh_token(client, admin_user, admin_headers):
    res = client.post("/api/v1/auth/refresh", headers=admin_headers)
    assert res.status_code == 200
    assert "access_token" in res.json()


def test_logout(client, admin_user, admin_headers):
    res = client.post("/api/v1/auth/logout", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["message"] == "Logged out successfully"
