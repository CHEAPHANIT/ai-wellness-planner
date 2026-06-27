from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "NutriAI API"
    environment: str = "development"
    database_url: str = Field(
        default="postgresql+psycopg://postgres:postgres@localhost:5433/ai_meal_planning",
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
    ai_provider: str = Field(default="auto", alias="AI_PROVIDER")
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4o-mini", alias="OPENAI_MODEL")
    openai_base_url: str = Field(default="https://api.openai.com/v1", alias="OPENAI_BASE_URL")
    ollama_base_url: str = Field(default="http://host.docker.internal:11434", alias="OLLAMA_BASE_URL")
    ollama_model: str = Field(default="llama3.1:8b", alias="OLLAMA_MODEL")
    ai_connect_timeout_seconds: float = Field(default=2.0, alias="AI_CONNECT_TIMEOUT_SECONDS", gt=0)
    ai_response_timeout_seconds: float = Field(default=45.0, alias="AI_RESPONSE_TIMEOUT_SECONDS", gt=0)
    app_timezone: str = Field(default="Asia/Bangkok", alias="APP_TIMEZONE")

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @field_validator("database_url", mode="before")
    @classmethod
    def use_psycopg_driver(cls, value: str) -> str:
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+psycopg://", 1)
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+psycopg://", 1)
        return value

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
