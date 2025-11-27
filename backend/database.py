"""
Database configuration and models for Hot and Cold Game
Uses SQLite with SQLAlchemy
"""

from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, Enum, Float, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime, timezone
import enum

# Database URL - SQLite file
DATABASE_URL = "sqlite:///./hotncold.db"

# Create engine
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}  # Needed for SQLite
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


class FriendshipStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"


class User(Base):
    """User model"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=True)
    password_hash = Column(String(255), nullable=False)
    avatar_path = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    sent_requests = relationship(
        "Friendship",
        foreign_keys="Friendship.user_id",
        back_populates="sender"
    )
    received_requests = relationship(
        "Friendship",
        foreign_keys="Friendship.friend_id",
        back_populates="receiver"
    )
    game_sessions = relationship("GameSession", back_populates="user")


class Friendship(Base):
    """Friendship model for friend requests and connections"""
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    friend_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(FriendshipStatus), default=FriendshipStatus.PENDING)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    sender = relationship("User", foreign_keys=[user_id], back_populates="sent_requests")
    receiver = relationship("User", foreign_keys=[friend_id], back_populates="received_requests")


class GameSession(Base):
    """Game session model for tracking player progress"""
    __tablename__ = "game_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    game_date = Column(String(10), nullable=False)  # YYYY-MM-DD format
    game_mode = Column(String(20), default="daily")  # daily, shot, etc.
    attempts = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    won = Column(Boolean, default=False)
    completion_time = Column(Float, nullable=True)  # Time in seconds
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="game_sessions")


def init_db():
    """Create all tables"""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
