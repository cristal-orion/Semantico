"""
User routes for Hot and Cold Game
/api/users/* endpoints
"""

import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from PIL import Image
import io

from database import get_db, User
from auth import UserResponse, get_current_user_required

router = APIRouter(prefix="/api/users", tags=["Users"])

UPLOAD_DIR = "uploads"
AVATAR_SIZE = (200, 200)
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


def resize_image(image_data: bytes, size: tuple = AVATAR_SIZE) -> bytes:
    """Resize image to specified size, maintaining aspect ratio with crop"""
    img = Image.open(io.BytesIO(image_data))

    # Convert to RGB if necessary (for PNG with transparency)
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")

    # Calculate dimensions to maintain aspect ratio with center crop
    width, height = img.size
    target_width, target_height = size

    # Calculate ratios
    ratio_w = target_width / width
    ratio_h = target_height / height

    # Use the larger ratio to ensure image fills the target size
    ratio = max(ratio_w, ratio_h)

    # Resize
    new_width = int(width * ratio)
    new_height = int(height * ratio)
    img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Center crop
    left = (new_width - target_width) // 2
    top = (new_height - target_height) // 2
    right = left + target_width
    bottom = top + target_height
    img = img.crop((left, top, right, bottom))

    # Save to bytes
    output = io.BytesIO()
    img.save(output, format="JPEG", quality=85)
    output.seek(0)

    return output.getvalue()


@router.post("/avatar", response_model=UserResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Upload or update user avatar

    - Accepts: JPG, PNG, GIF, WebP
    - Max size: 5MB
    - Will be resized to 200x200px
    """
    # Validate file extension
    ext = os.path.splitext(file.filename)[1].lower() if file.filename else ""

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Formato file non supportato. Usa: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    # Read file content
    content = await file.read()

    # Validate file size
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File troppo grande. Massimo 5MB"
        )

    # Resize image
    try:
        resized_content = resize_image(content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Errore nel processare l'immagine: {str(e)}"
        )

    # Generate unique filename
    filename = f"avatar_{current_user.id}_{uuid.uuid4().hex[:8]}.jpg"
    filepath = os.path.join(UPLOAD_DIR, filename)

    # Delete old avatar if exists
    if current_user.avatar_path:
        old_path = current_user.avatar_path.lstrip("/")
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
            except:
                pass  # Ignore errors on old file deletion

    # Save new avatar
    with open(filepath, "wb") as f:
        f.write(resized_content)

    # Update user in database
    current_user.avatar_path = f"/uploads/{filename}"
    db.commit()
    db.refresh(current_user)

    return UserResponse.model_validate(current_user)


@router.delete("/avatar", response_model=UserResponse)
async def delete_avatar(
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """Delete user avatar"""
    if current_user.avatar_path:
        old_path = current_user.avatar_path.lstrip("/")
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
            except:
                pass

        current_user.avatar_path = None
        db.commit()
        db.refresh(current_user)

    return UserResponse.model_validate(current_user)


@router.get("/search")
async def search_users(
    q: str,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Search users by username

    - **q**: Search query (min 2 chars)
    - Returns max 20 users matching the query
    """
    if len(q) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Query deve essere almeno 2 caratteri"
        )

    users = db.query(User).filter(
        User.username.ilike(f"%{q}%"),
        User.id != current_user.id  # Exclude self
    ).limit(20).all()

    return [
        {
            "id": user.id,
            "username": user.username,
            "avatar_path": user.avatar_path
        }
        for user in users
    ]


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """Get user by ID"""
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utente non trovato"
        )

    return UserResponse.model_validate(user)
