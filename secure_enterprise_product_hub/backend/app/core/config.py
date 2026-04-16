from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Secure Enterprise Product Hub"
    api_prefix: str = "/api"
    mongo_uri: str = "mongodb://localhost:27017"
    mongo_db: str = "secure_product_hub"
    jwt_secret: str = "change-this-secret-before-production"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 60
    upload_dir: Path = Path("uploads")
    public_base_url: str = "http://localhost:8000"
    allowed_origins: list[str] = ["*"]

    class Config:
        env_file = ".env"
        env_prefix = "SPH_"


@lru_cache
def get_settings() -> Settings:
    return Settings()
