import os
from pathlib import Path
import pymysql
from dotenv import dotenv_values

ENVIRONMENTS = ["dev", "test", "prod"]
REQUIRED = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME"]
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def get_environment():
    env = os.getenv("APP_ENV", "dev").strip().lower()
    if env not in ENVIRONMENTS:
        raise SystemExit(
            f"Unknown APP_ENV '{env}'. Use one of: {', '.join(ENVIRONMENTS)}"
        )
    return env


def load_settings(env):
    path = PROJECT_ROOT / f".env.{env}"
    if path.exists():
        settings = dotenv_values(path)
    else:
        settings = {
            k: os.getenv(k)
            for k in REQUIRED + ["DB_SSL_CA", "DB_SSL_CA_CONTENT"]
        }

    missing = [k for k in REQUIRED if not settings.get(k)]
    if missing:
        raise SystemExit(f"Missing settings for '{env}': {', '.join(missing)}")
    return settings


def connect():
    env = get_environment()
    s = load_settings(env)
    options = dict(
        host=s["DB_HOST"],
        port=int(s["DB_PORT"]),
        user=s["DB_USER"],
        password=s["DB_PASSWORD"],
        database=s["DB_NAME"],
        charset="utf8mb4",
    )

    if s.get("DB_SSL_CA_CONTENT"):
        ca_path = Path("/tmp/aiven_ca.pem")
        ca_path.write_text(s["DB_SSL_CA_CONTENT"], encoding="utf-8")
        options["ssl_ca"] = str(ca_path)
    elif s.get("DB_SSL_CA"):
        options["ssl_ca"] = s["DB_SSL_CA"]

    return pymysql.connect(**options)