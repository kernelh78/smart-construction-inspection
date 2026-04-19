import pytest


SITE_PAYLOAD = {
    "name": "점검 테스트 현장",
    "address": "서울시 종로구 1",
}


@pytest.fixture()
def site(client, admin_user, admin_headers):
    res = client.post("/api/v1/sites/", json=SITE_PAYLOAD, headers=admin_headers)
    assert res.status_code == 201
    return res.json()


@pytest.fixture()
def inspection_payload(site, inspector_user):
    return {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
        "status": "pending",
        "memo": "테스트 점검",
    }


def test_create_inspection(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
        "memo": "테스트 점검",
    }
    res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    assert res.status_code == 201
    body = res.json()
    assert body["category"] == "골조"
    assert body["site_id"] == site["id"]


def test_create_inspection_invalid_site(client, admin_headers, inspector_user):
    payload = {
        "site_id": "nonexistent-site",
        "inspector_id": inspector_user.id,
        "category": "설비",
    }
    res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    assert res.status_code == 404


def test_create_inspection_invalid_inspector(client, admin_headers, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": "nonexistent-user",
        "category": "전기",
    }
    res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    assert res.status_code == 404


def test_get_inspections(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
    }
    client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    res = client.get("/api/v1/inspections/", headers=admin_headers)
    assert res.status_code == 200
    assert len(res.json()) >= 1


def test_get_inspections_by_site(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "설비",
    }
    client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    res = client.get(f"/api/v1/inspections/?site_id={site['id']}", headers=admin_headers)
    assert res.status_code == 200
    assert all(i["site_id"] == site["id"] for i in res.json())


def test_get_inspection_detail(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "전기",
    }
    create_res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    inspection_id = create_res.json()["id"]

    res = client.get(f"/api/v1/inspections/{inspection_id}", headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["id"] == inspection_id


def test_get_inspection_not_found(client, admin_headers):
    res = client.get("/api/v1/inspections/nonexistent-id", headers=admin_headers)
    assert res.status_code == 404


def test_update_inspection(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
        "status": "pending",
    }
    create_res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    inspection_id = create_res.json()["id"]

    res = client.put(
        f"/api/v1/inspections/{inspection_id}",
        json={"status": "pass", "memo": "이상 없음"},
        headers=admin_headers,
    )
    assert res.status_code == 200
    assert res.json()["status"] == "pass"
    assert res.json()["memo"] == "이상 없음"


def test_delete_inspection(client, admin_headers, inspector_user, site):
    payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
    }
    create_res = client.post("/api/v1/inspections/", json=payload, headers=admin_headers)
    inspection_id = create_res.json()["id"]

    res = client.delete(f"/api/v1/inspections/{inspection_id}", headers=admin_headers)
    assert res.status_code == 200

    get_res = client.get(f"/api/v1/inspections/{inspection_id}", headers=admin_headers)
    assert get_res.status_code == 404


def test_create_defect(client, admin_headers, inspector_user, site):
    insp_payload = {
        "site_id": site["id"],
        "inspector_id": inspector_user.id,
        "category": "골조",
    }
    create_res = client.post("/api/v1/inspections/", json=insp_payload, headers=admin_headers)
    inspection_id = create_res.json()["id"]

    defect_payload = {"severity": "critical", "description": "균열 발견"}
    res = client.post(
        f"/api/v1/inspections/{inspection_id}/defects",
        json=defect_payload,
        headers=admin_headers,
    )
    assert res.status_code == 200
    body = res.json()
    assert body["severity"] == "critical"
    assert body["description"] == "균열 발견"
    assert body["inspection_id"] == inspection_id


def test_create_defect_invalid_inspection(client, admin_headers):
    res = client.post(
        "/api/v1/inspections/nonexistent/defects",
        json={"severity": "minor", "description": "테스트"},
        headers=admin_headers,
    )
    assert res.status_code == 404
