import datetime
from typing import Optional

from sqlalchemy import (JSON, Boolean, DateTime, ForeignKey, Integer, String,
                        Text, UniqueConstraint)
from sqlalchemy.ext.asyncio import (AsyncAttrs, async_sessionmaker,
                                    create_async_engine)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

async_engine = create_async_engine("sqlite+aiosqlite:////var/sqlite/wakimae/app.db")
AsyncSession = async_sessionmaker(expire_on_commit=False)
AsyncSession.configure(bind=async_engine)


class Base(AsyncAttrs, DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "user"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    account_id: Mapped[str] = mapped_column(
        String(128), index=True, unique=True, nullable=False
    )
    email: Mapped[str] = mapped_column(
        String(128), index=True, unique=True, nullable=False
    )
    refresh_token: Mapped[str] = mapped_column(String(128), nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )
    cursor: "Mapped[Optional[SyncCursor]]" = relationship(back_populates="user")


class SyncCursor(Base):
    __tablename__ = "sync_cursor"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    cursor: Mapped[str] = mapped_column(String(128), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)
    user: Mapped[User] = relationship(back_populates="cursor")

    __table_args__ = (UniqueConstraint("user_id"),)


class File(Base):
    __tablename__ = "file"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    content_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)
    pending_edits: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    external_id: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    path: Mapped[str] = mapped_column(String(256), nullable=False)
    rev: Mapped[str] = mapped_column(String(128), nullable=False)

    def __repr__(self) -> str:
        return f"<File {self.id} external_id={self.external_id} path={self.path} pending_edits={self.pending_edits} content_hash={self.content_hash} user_id={self.user_id} rev={self.rev}>"

    __table_args__ = (UniqueConstraint("user_id", "path"),)


class Tombstone(Base):
    __tablename__ = "tombstone"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)
    external_id: Mapped[str] = mapped_column(String(128), nullable=False)
    path: Mapped[str] = mapped_column(String(256), nullable=False)
    rev: Mapped[str] = mapped_column(String(128), nullable=False)

    __table_args__ = (UniqueConstraint("user_id", "path"),)
