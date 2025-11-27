"""
Authentication routes for Hot and Cold Game
/api/auth/* endpoints
"""

from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db, User
from auth import (
    UserCreate,
    UserLogin,
    UserResponse,
    Token,
    authenticate_user,
    create_user,
    create_access_token,
    get_user_by_username,
    get_user_by_email,
    get_current_user_required,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=Token)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user

    - **username**: Unique username (3-50 chars, alphanumeric + underscore)
    - **username**: Unique username (3-50 chars, alphanumeric + underscore)
    - **email**: Optional email address
    - **password**: Password (min 6 chars)
    - **password**: Password (min 6 chars)
    """
    # Validate username format
    username = user_data.username.lower().strip()

    if len(username) < 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username deve essere almeno 3 caratteri"
        )

    if len(username) > 50:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username deve essere massimo 50 caratteri"
        )

    if not username.replace("_", "").isalnum():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username può contenere solo lettere, numeri e underscore"
        )

    # Validate password
    if len(user_data.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password deve essere almeno 6 caratteri"
        )

    # Check if username exists
    if get_user_by_username(db, username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username già in uso"
        )

    # Check if email exists
    if user_data.email and get_user_by_email(db, user_data.email.lower()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email già registrata"
        )

    # Create user
    user_data.username = username
    db_user = create_user(db, user_data)

    # Create token (sub must be a string for JWT standard)
    access_token = create_access_token(
        data={"sub": str(db_user.id)},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(db_user)
    )


@router.post("/login", response_model=Token)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """
    Login with username/email and password

    - **username**: Username or email
    - **password**: Password
    """
    user = authenticate_user(db, user_data.username, user_data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenziali non valide",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create token (sub must be a string for JWT standard)
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user_required)):
    """
    Get current authenticated user info

    Requires: Bearer token in Authorization header
    """
    return UserResponse.model_validate(current_user)


@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user_required)):
    """
    Logout current user

    Note: With JWT, logout is handled client-side by deleting the token.
    This endpoint is for API consistency and could be used for token blacklisting.
    """
    # With stateless JWT, we just return success
    # The client should delete the token
    return {"message": "Logout effettuato con successo"}
