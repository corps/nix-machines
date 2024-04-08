import os.path

if os.path.exists("/run/secrets/wakimae_env") and os.path.isfile("/run/secrets/wakimae_env"):
    with open("/run/secrets/wakimae_env", "r") as env_file:
        for line in env_file.readlines():
            k, v = line.strip().split("=")
            os.environ[k] = v

storage_secret: str = os.environ.get("STORAGE_SECRET", "test-secret")

if os.path.exists("/run/secrets/wakimae_storage_secret"):
    storage_secret = open("/run/secrets/wakimae_storage_secret").read().strip()

port: int = int(os.environ.get("PORT", 8080))
sentry_dsn: str = os.environ["SENTRY_DSN"]
dropbox_app_key: str = os.environ["DROPBOX_APP_KEY"]
dropbox_app_secret: str = os.environ["DROPBOX_APP_SECRET"]
dropbox_test_token: str = os.environ.get("DROPBOX_TOKEN", "")
dropbox_user_token: str = dropbox_test_token
store_prefix: str = "/var/store"
