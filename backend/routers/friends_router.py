"""
Friends routes for Hot and Cold Game
/api/friends/* endpoints
"""

from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from pydantic import BaseModel

from database import get_db, User, Friendship, FriendshipStatus
from auth import get_current_user_required

router = APIRouter(prefix="/api/friends", tags=["Friends"])


class FriendResponse(BaseModel):
    id: int
    username: str
    avatar_path: Optional[str]
    status: str  # "accepted", "pending_sent", "pending_received"
    friendship_id: int


class FriendRequestRequest(BaseModel):
    friend_id: int


class FriendRequestResponse(BaseModel):
    id: int
    user_id: int
    friend_id: int
    status: str


@router.get("")
async def get_friends(
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
) -> dict:
    """
    Get list of friends and pending requests.
    Returns:
    - friends: List of accepted friends
    - pending_sent: Requests you sent that are pending
    - pending_received: Requests you received that are pending
    """
    # Get all friendships involving current user
    friendships = db.query(Friendship).filter(
        or_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == current_user.id
        )
    ).all()

    friends = []
    pending_sent = []
    pending_received = []

    for f in friendships:
        # Determine the other user
        if f.user_id == current_user.id:
            other_user = db.query(User).filter(User.id == f.friend_id).first()
            is_sender = True
        else:
            other_user = db.query(User).filter(User.id == f.user_id).first()
            is_sender = False

        if not other_user:
            continue

        friend_data = FriendResponse(
            id=other_user.id,
            username=other_user.username,
            avatar_path=other_user.avatar_path,
            status=f.status.value,
            friendship_id=f.id
        )

        if f.status == FriendshipStatus.ACCEPTED:
            friends.append(friend_data)
        elif f.status == FriendshipStatus.PENDING:
            if is_sender:
                pending_sent.append(friend_data)
            else:
                pending_received.append(friend_data)

    return {
        "friends": friends,
        "pending_sent": pending_sent,
        "pending_received": pending_received
    }


@router.post("/request")
async def send_friend_request(
    request: FriendRequestRequest,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Send a friend request to another user.
    """
    if request.friend_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Non puoi aggiungere te stesso come amico"
        )

    # Check if target user exists
    target_user = db.query(User).filter(User.id == request.friend_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utente non trovato"
        )

    # Check if friendship already exists (in either direction)
    existing = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == request.friend_id
            ),
            and_(
                Friendship.user_id == request.friend_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if existing:
        if existing.status == FriendshipStatus.ACCEPTED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Siete già amici"
            )
        elif existing.status == FriendshipStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Richiesta di amicizia già inviata"
            )
        elif existing.status == FriendshipStatus.REJECTED:
            # Allow resending after rejection
            existing.status = FriendshipStatus.PENDING
            existing.created_at = datetime.now(timezone.utc)
            db.commit()
            return {"message": "Richiesta di amicizia inviata", "friendship_id": existing.id}

    # Create new friendship request
    friendship = Friendship(
        user_id=current_user.id,
        friend_id=request.friend_id,
        status=FriendshipStatus.PENDING
    )
    db.add(friendship)
    db.commit()
    db.refresh(friendship)

    return {"message": "Richiesta di amicizia inviata", "friendship_id": friendship.id}


@router.post("/accept/{friendship_id}")
async def accept_friend_request(
    friendship_id: int,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Accept a pending friend request.
    """
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        Friendship.friend_id == current_user.id,  # Must be the receiver
        Friendship.status == FriendshipStatus.PENDING
    ).first()

    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Richiesta di amicizia non trovata"
        )

    friendship.status = FriendshipStatus.ACCEPTED
    db.commit()

    return {"message": "Richiesta di amicizia accettata"}


@router.post("/reject/{friendship_id}")
async def reject_friend_request(
    friendship_id: int,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Reject a pending friend request.
    """
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        Friendship.friend_id == current_user.id,  # Must be the receiver
        Friendship.status == FriendshipStatus.PENDING
    ).first()

    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Richiesta di amicizia non trovata"
        )

    friendship.status = FriendshipStatus.REJECTED
    db.commit()

    return {"message": "Richiesta di amicizia rifiutata"}


@router.delete("/{friendship_id}")
async def remove_friend(
    friendship_id: int,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Remove a friend or cancel a pending request.
    """
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        or_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == current_user.id
        )
    ).first()

    if not friendship:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Amicizia non trovata"
        )

    db.delete(friendship)
    db.commit()

    return {"message": "Amicizia rimossa"}
