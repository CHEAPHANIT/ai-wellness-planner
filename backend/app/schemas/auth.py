from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=160)
    password: str = Field(min_length=8, max_length=128)


class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=160)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MessageResponse(BaseModel):
    message: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    message: str
    demo_otp: str


class OTPVerificationRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=4, max_length=12)


class ChangePasswordRequest(BaseModel):
    email: EmailStr | None = None
    old_password: str | None = Field(default=None, min_length=8, max_length=128)
    otp: str | None = Field(default=None, min_length=4, max_length=12)
    new_password: str = Field(min_length=8, max_length=128)
