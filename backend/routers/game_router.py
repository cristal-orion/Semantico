"""
Game routes for Hot and Cold Game
/api/game/* endpoints for tracking progress and stats
"""

from datetime import datetime, timezone
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from pydantic import BaseModel

from database import get_db, User, GameSession, Friendship, FriendshipStatus
from auth import get_current_user_required, get_current_user

router = APIRouter(prefix="/api/game", tags=["Game"])


# Pydantic models
class PlayerProgress(BaseModel):
    user_id: int
    username: str
    avatar_path: Optional[str]
    best_rank: int  # Best rank achieved (lower is better, closer to word)
    attempts: int
    completed: bool
    won: bool
    is_friend: bool = False
    hints_used: int = 0


class UpdateProgressRequest(BaseModel):
    game_date: str  # YYYY-MM-DD
    game_mode: str = "daily"  # daily, shot
    best_rank: int
    attempts: int
    completed: bool = False
    won: bool = False


class GameStatsResponse(BaseModel):
    total_games: int
    games_won: int
    current_streak: int
    best_streak: int
    average_attempts: float
    games_by_mode: dict
    total_hints: int = 0


# In-memory storage for real-time progress (could use Redis in production)
# Format: {game_date: {user_id: {best_rank, attempts, completed, won}}}
active_players: dict = {}


@router.post("/progress")
async def update_progress(
    request: UpdateProgressRequest,
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Update player progress for a game session.
    Called after each guess to update the player's position on the progress bar.
    """
    game_key = f"{request.game_date}_{request.game_mode}"

    # Prima controlla se esiste una sessione nel DB per prendere hints_used
    existing_session = db.query(GameSession).filter(
        GameSession.user_id == current_user.id,
        GameSession.game_date == request.game_date,
        GameSession.game_mode == request.game_mode
    ).first()

    # Prendi hints_used dal DB se esiste, altrimenti 0
    current_hints = existing_session.hints_used if existing_session and hasattr(existing_session, 'hints_used') else 0

    # Update in-memory storage for real-time display
    if game_key not in active_players:
        active_players[game_key] = {}

    active_players[game_key][current_user.id] = {
        "user_id": current_user.id,
        "username": current_user.username,
        "avatar_path": current_user.avatar_path,
        "best_rank": request.best_rank,
        "attempts": request.attempts,
        "completed": request.completed,
        "won": request.won,
        "hints_used": current_hints,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    # Update/create session nel DB
    if existing_session:
        existing_session.attempts = request.attempts
        existing_session.completed = request.completed
        existing_session.won = request.won
        if request.completed:
            existing_session.completed_at = datetime.now(timezone.utc)
    else:
        existing_session = GameSession(
            user_id=current_user.id,
            game_date=request.game_date,
            game_mode=request.game_mode,
            attempts=request.attempts,
            completed=request.completed,
            won=request.won
        )
        db.add(existing_session)

    db.commit()

    return {"status": "ok"}


@router.get("/players/{game_date}")
async def get_active_players(
    game_date: str,
    game_mode: str = "daily",
    friends_only: bool = False,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[PlayerProgress]:
    """
    Get list of players currently playing or who played this game.
    Returns their progress (position on the hot-cold bar).
    """
    game_key = f"{game_date}_{game_mode}"

    # Get friend IDs if user is authenticated
    friend_ids = set()
    if current_user:
        friendships = db.query(Friendship).filter(
            and_(
                Friendship.status == FriendshipStatus.ACCEPTED,
                (Friendship.user_id == current_user.id) | (Friendship.friend_id == current_user.id)
            )
        ).all()

        for f in friendships:
            if f.user_id == current_user.id:
                friend_ids.add(f.friend_id)
            else:
                friend_ids.add(f.user_id)

    players = []

    # Get from in-memory storage (active players)
    if game_key in active_players:
        for user_id, data in active_players[game_key].items():
            # Filter by friends if requested
            if friends_only and current_user:
                if user_id not in friend_ids and user_id != current_user.id:
                    continue

            players.append(PlayerProgress(
                user_id=data["user_id"],
                username=data["username"],
                avatar_path=data["avatar_path"],
                best_rank=data["best_rank"],
                attempts=data["attempts"],
                completed=data["completed"],
                won=data["won"],
                is_friend=user_id in friend_ids,
                hints_used=data.get("hints_used", 0)
            ))

    # Also get from database (players who completed but aren't in memory)
    db_sessions = db.query(GameSession, User).join(User).filter(
        GameSession.game_date == game_date,
        GameSession.game_mode == game_mode
    ).all()

    existing_ids = {p.user_id for p in players}

    for session, user in db_sessions:
        if user.id not in existing_ids:
            if friends_only and current_user:
                if user.id not in friend_ids and user.id != current_user.id:
                    continue

            # For completed games from DB, we don't have best_rank stored
            # Use attempts as proxy (lower is better)
            players.append(PlayerProgress(
                user_id=user.id,
                username=user.username,
                avatar_path=user.avatar_path,
                best_rank=session.attempts * 100 if session.won else 99999,  # Estimate
                attempts=session.attempts,
                completed=session.completed,
                won=session.won,
                is_friend=user.id in friend_ids,
                hints_used=session.hints_used if hasattr(session, 'hints_used') else 0
            ))

    # Sort by best_rank (best players first)
    players.sort(key=lambda p: (not p.won, p.best_rank))

    return players


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
) -> GameStatsResponse:
    """
    Get statistics for the current user.
    """
    sessions = db.query(GameSession).filter(
        GameSession.user_id == current_user.id
    ).order_by(GameSession.game_date.desc()).all()

    total_games = len(sessions)
    games_won = sum(1 for s in sessions if s.won)

    # Calculate streaks
    current_streak = 0
    best_streak = 0
    temp_streak = 0

    for session in sessions:
        if session.won:
            temp_streak += 1
            if temp_streak > best_streak:
                best_streak = temp_streak
        else:
            if temp_streak == current_streak or current_streak == 0:
                current_streak = temp_streak
            temp_streak = 0

    if temp_streak > 0 and current_streak == 0:
        current_streak = temp_streak

    # Average attempts for won games
    won_sessions = [s for s in sessions if s.won]
    average_attempts = sum(s.attempts for s in won_sessions) / len(won_sessions) if won_sessions else 0

    # Games by mode
    games_by_mode = {}
    for session in sessions:
        mode = session.game_mode
        if mode not in games_by_mode:
            games_by_mode[mode] = {"total": 0, "won": 0}
        games_by_mode[mode]["total"] += 1
        if session.won:
            games_by_mode[mode]["won"] += 1

    # Calcola totale hints usati
    total_hints = sum(s.hints_used if hasattr(s, 'hints_used') else 0 for s in sessions)

    return GameStatsResponse(
        total_games=total_games,
        games_won=games_won,
        current_streak=current_streak,
        best_streak=best_streak,
        average_attempts=round(average_attempts, 1),
        games_by_mode=games_by_mode,
        total_hints=total_hints
    )


@router.get("/history")
async def get_user_game_history(
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Get complete game history for the current user.
    Returns list of all games played with date, attempts, won status.
    """
    sessions = db.query(GameSession).filter(
        GameSession.user_id == current_user.id
    ).order_by(GameSession.game_date.desc()).all()

    history = []
    for session in sessions:
        history.append({
            "game_date": session.game_date,
            "game_mode": session.game_mode,
            "attempts": session.attempts,
            "completed": session.completed,
            "won": session.won,
            "completed_at": session.completed_at.isoformat() if session.completed_at else None
        })

    return history


@router.get("/friends/status/{game_date}")
async def get_friends_game_status(
    game_date: str,
    game_mode: str = "daily",
    current_user: User = Depends(get_current_user_required),
    db: Session = Depends(get_db)
):
    """
    Get game status for all friends (have they played? did they win? how many attempts?).
    """
    # Get friend IDs
    friendships = db.query(Friendship).filter(
        and_(
            Friendship.status == FriendshipStatus.ACCEPTED,
            (Friendship.user_id == current_user.id) | (Friendship.friend_id == current_user.id)
        )
    ).all()

    friend_ids = []
    for f in friendships:
        if f.user_id == current_user.id:
            friend_ids.append(f.friend_id)
        else:
            friend_ids.append(f.user_id)

    if not friend_ids:
        return []

    # Get friends and their game sessions
    friends_status = []

    for friend_id in friend_ids:
        friend = db.query(User).filter(User.id == friend_id).first()
        if not friend:
            continue

        session = db.query(GameSession).filter(
            GameSession.user_id == friend_id,
            GameSession.game_date == game_date,
            GameSession.game_mode == game_mode
        ).first()

        friends_status.append({
            "user_id": friend.id,
            "username": friend.username,
            "avatar_path": friend.avatar_path,
            "played": session is not None,
            "completed": session.completed if session else False,
            "won": session.won if session else False,
            "attempts": session.attempts if session else None
        })

    # Sort: completed first, then by attempts
    friends_status.sort(key=lambda x: (not x["completed"], x["attempts"] or 999))

    return friends_status
