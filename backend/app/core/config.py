from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "NutriAI API"
    environment: str = "development"
    database_url: str = Field(
        default="postgresql+psycopg://postgres:postgres@localhost:5432/ai_meal_planning",
        alias="DATABASE_URL",
    )
    secret_key: str = Field(default="change-this-secret-key", alias="SECRET_KEY")
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24
    backend_cors_origins: str = Field(default="http://localhost:5173,http://localhost:8080")
    backend_cors_origin_regex: str | None = Field(
        default=r"http://(localhost|127\.0\.0\.1):\d+",
        alias="BACKEND_CORS_ORIGIN_REGEX",
    )
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.backend_cors_origins.split(",") if origin.strip()]

    @property
    def cors_origin_regex(self) -> str | None:
        if self.backend_cors_origin_regex is None:
            return None
        value = self.backend_cors_origin_regex.strip()
        return value or None


settings = Settings()
