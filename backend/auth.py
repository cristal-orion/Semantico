"""
Authentication utilities for Hot and Cold Game
JWT token management and password hashing
"""

from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr

from database import get_db, User

# Configuration
SECRET_KEY = "your-secret-key-change-in-production-use-env-variable"  # TODO: Move to env
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


# Pydantic models for auth
class UserCreate(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    password: str


class UserLogin(BaseModel):
    username: str  # Can be username or email
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: Optional[str] = None
    avatar_path: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class TokenData(BaseModel):
    user_id: Optional[int] = None


# Password utilities
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        hashed_password.encode('utf-8')
    )


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')


# JWT utilities
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

    return encoded_jwt


def decode_token(token: str) -> Optional[TokenData]:
    """Decode and validate a JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id_str = payload.get("sub")

        if user_id_str is None:
            return None

        # Convert string to int
        user_id = int(user_id_str)
        return TokenData(user_id=user_id)
    except (JWTError, ValueError):
        return None


# User utilities
def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """Get user by username"""
    return db.query(User).filter(User.username == username).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    """Get user by ID"""
    return db.query(User).filter(User.id == user_id).first()


def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    """Authenticate user by username/email and password"""
    # Try username first
    user = get_user_by_username(db, username)

    # If not found, try email
    if not user:
        user = get_user_by_email(db, username)

    if not user:
        return None

    if not verify_password(password, user.password_hash):
        return None

    return user


def create_user(db: Session, user_data: UserCreate) -> User:
    """Create a new user"""
    hashed_password = get_password_hash(user_data.password)

    email_to_use = user_data.email
    if not email_to_use:
        email_to_use = f"{user_data.username}@noemail.local"

    db_user = User(
        username=user_data.username.lower(),
        email=email_to_use.lower(),
        password_hash=hashed_password
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user


# Dependency to get current user
async def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """Get current authenticated user from JWT token"""
    if not token:
        return None

    token_data = decode_token(token)

    if token_data is None or token_data.user_id is None:
        return None

    user = get_user_by_id(db, token_data.user_id)

    return user


async def get_current_user_required(
    current_user: Optional[User] = Depends(get_current_user)
) -> User:
    """Require authenticated user (raises 401 if not authenticated)"""
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Non autenticato",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return current_user
