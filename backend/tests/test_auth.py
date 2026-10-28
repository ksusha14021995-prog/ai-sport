from tests.conftest import CONSENT_VERSION, register


async def test_health(client):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_register_then_login(client):
    await register(client, email="Anna@Example.com")

    response = await client.post("/api/v1/auth/login", json={"email": "anna@example.com", "password": "s3cret-pass"})
    assert response.status_code == 200
    token = response.json()["access_token"]

    me = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "anna@example.com"
    assert me.json()["consent_version"] == CONSENT_VERSION
    assert "password_hash" not in me.json()


async def test_login_wrong_password(client):
    await register(client)
    response = await client.post("/api/v1/auth/login", json={"email": "user@example.com", "password": "wrong-pass"})
    assert response.status_code == 401
    unknown = await client.post("/api/v1/auth/login", json={"email": "nobody@example.com", "password": "wrong-pass"})
    assert unknown.status_code == 401


async def test_duplicate_email_conflict(client):
    await register(client)
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": "USER@example.com", "password": "another-pass", "consent": {"accepted": True, "version": CONSENT_VERSION}},
    )
    assert response.status_code == 409


async def test_register_requires_consent(client):
    base = {"email": "x@example.com", "password": "s3cret-pass"}
    missing = await client.post("/api/v1/auth/register", json=base)
    declined = await client.post("/api/v1/auth/register", json={**base, "consent": {"accepted": False, "version": CONSENT_VERSION}})
    stale = await client.post("/api/v1/auth/register", json={**base, "consent": {"accepted": True, "version": "old"}})
    assert (missing.status_code, declined.status_code, stale.status_code) == (422, 422, 422)


async def test_auth_required(client):
    for method, url in [
        ("GET", "/api/v1/me"),
        ("GET", "/api/v1/me/profile"),
        ("PUT", "/api/v1/me/profile"),
        ("PUT", "/api/v1/me/plan"),
        ("POST", "/api/v1/me/workouts"),
        ("GET", "/api/v1/me/workouts"),
        ("GET", "/api/v1/me/progress"),
        ("DELETE", "/api/v1/me"),
    ]:
        response = await client.request(method, url, json={})
        assert response.status_code == 401, (method, url)

    bad_token = await client.get("/api/v1/me", headers={"Authorization": "Bearer not-a-jwt"})
    assert bad_token.status_code == 401
