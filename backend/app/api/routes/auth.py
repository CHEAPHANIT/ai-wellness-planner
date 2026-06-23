from datetime import timedelta
import random

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    MessageResponse,
    OTPVerificationRequest,
    Token,
    UserCreate,
    UserRead,
    UserUpdate,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)) -> UserRead:
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email is already registered")

    user = User(
        email=payload.email.lower(),
        full_name=payload.full_name,
        hashed_password=get_password_hash(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
) -> Token:
    user = db.query(User).filter(User.email == form_data.username.lower()).first()
    if user is None or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    expires = timedelta(minutes=settings.access_token_expire_minutes)
    token = create_access_token(subject=str(user.id), expires_delta=expires)
    return Token(access_token=token)


@router.get("/me", response_model=UserRead)
def read_current_user(current_user: User = Depends(get_current_user)) -> UserRead:
    return current_user


@router.put("/me", response_model=UserRead)
def update_current_user(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserRead:
    email = payload.email.lower()
    existing = db.query(User).filter(User.email == email, User.id != current_user.id).first()
    if existing is not None:
        raise HTTPException(status_code=409, detail="Email is already registered")
    current_user.email = email
    current_user.full_name = payload.full_name.strip()
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/logout", response_model=MessageResponse)
def logout(_: User = Depends(get_current_user)) -> MessageResponse:
    return MessageResponse(message="Logged out. Remove the JWT token on the client.")


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)) -> ForgotPasswordResponse:
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if user is None:
        raise HTTPException(status_code=404, detail="Email was not found")
    otp = f"{random.randint(100000, 999999)}"
    user.reset_otp = otp
    user.otp_verified = False
    db.commit()
    return ForgotPasswordResponse(
        message="OTP generated. In production, send it by email or SMS.",
        demo_otp=otp,
    )


@router.post("/verify-otp", response_model=MessageResponse)
def verify_otp(payload: OTPVerificationRequest, db: Session = Depends(get_db)) -> MessageResponse:
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if user is None or user.reset_otp != payload.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    user.otp_verified = True
    db.commit()
    return MessageResponse(message="OTP verified")


@router.post("/change-password", response_model=MessageResponse)
def change_password(
    payload: ChangePasswordRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    if payload.email is None:
        raise HTTPException(status_code=400, detail="Email is required")
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User was not found")

    old_password_ok = payload.old_password is not None and verify_password(payload.old_password, user.hashed_password)
    otp_ok = payload.otp is not None and user.reset_otp == payload.otp and user.otp_verified
    if not old_password_ok and not otp_ok:
        raise HTTPException(status_code=400, detail="Provide a valid old password or verified OTP")

    user.hashed_password = get_password_hash(payload.new_password)
    user.reset_otp = None
    user.otp_verified = False
    db.commit()
    return MessageResponse(message="Password changed")
