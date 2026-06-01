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
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.backend_cors_origins.split(",") if origin.strip()]


settings = Settings()
