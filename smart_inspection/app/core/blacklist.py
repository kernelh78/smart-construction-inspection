import redis
from ..config import settings

_redis: redis.Redis | None = None


def _get_redis() -> redis.Redis | None:
    global _redis
    if _redis is None:
        try:
            _redis = redis.from_url(settings.REDIS_URL, decode_responses=True)
            _redis.ping()
        except Exception:
            _redis = None
    return _redis


def blacklist_token(token: str, expires_in_seconds: int) -> None:
    r = _get_redis()
    if r:
        r.setex(f"bl:{token}", expires_in_seconds, "1")


def is_blacklisted(token: str) -> bool:
    r = _get_redis()
    if r is None:
        return False
    return r.exists(f"bl:{token}") == 1
