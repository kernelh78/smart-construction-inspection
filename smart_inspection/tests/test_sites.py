import pytest


SITE_PAYLOAD = {
    "name": "테스트 현장",
    "address": "서울시 강남구 테헤란로 1",
    "lat": 37.5665,
    "lng": 127.0000,
}


def test_create_site_as_admin(client, admin_user, admin_headers):
    res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    assert res.status_code == 201
    body = res.json()
    assert body["name"] == SITE_PAYLOAD["name"]
    assert body["address"] == SITE_PAYLOAD["address"]
    assert "id" in body


def test_create_site_as_inspector_forbidden(client, inspector_user, inspector_headers):
    res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=inspector_headers)
    assert res.status_code == 403


def test_create_site_without_token(client):
    res = client.post("/api/v1/sites/", json=SITE_PAYLOAD)
    assert res.status_code == 401


def test_get_sites(client, admin_user, admin_headers):
    client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    res = client.get("/api/v1/sites/", headers=admin_headers)
    assert res.status_code == 200
    assert len(res.json()) >= 1


def test_get_site_detail(client, admin_user, admin_headers):
    create_res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    site_id = create_res.json()["id"]

    res = client.get(f"/api/v1/sites/{site_id}", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["id"] == site_id


def test_get_site_not_found(client, admin_user, admin_headers):
    res = client.get("/api/v1/sites/nonexistent-id", headers=admin_headers)
    assert res.status_code == 404


def test_update_site_as_admin(client, admin_user, admin_headers):
    create_res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    site_id = create_res.json()["id"]

    res = client.put(
        f"/api/v1/sites/{site_id}",
        json={"name": "수정된 현장"},
        headers=admin_headers,
    )
    assert res.status_code == 200
    assert res.json()["name"] == "수정된 현장"


def test_update_site_as_inspector_forbidden(client, admin_user, admin_headers, inspector_user, inspector_headers):
    create_res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    site_id = create_res.json()["id"]

    res = client.put(
        f"/api/v1/sites/{site_id}",
        json={"name": "수정 시도"},
        headers=inspector_headers,
    )
    assert res.status_code == 403


def test_delete_site_as_admin(client, admin_user, admin_headers):
    create_res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    site_id = create_res.json()["id"]

    res = client.delete(f"/api/v1/sites/{site_id}", headers=admin_headers)
    assert res.status_code == 200

    get_res = client.get(f"/api/v1/sites/{site_id}", headers=admin_headers)
    assert get_res.status_code == 404


def test_delete_site_as_inspector_forbidden(client, admin_user, admin_headers, inspector_user, inspector_headers):
    create_res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    site_id = create_res.json()["id"]

    res = client.delete(f"/api/v1/sites/{site_id}", headers=inspector_headers)
    assert res.status_code == 403
