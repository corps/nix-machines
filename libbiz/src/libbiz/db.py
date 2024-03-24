import datetime

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

async_engine = create_async_engine("sqlite+aiosqlite:////var/sqlite/libbiz/app.db")
AsyncSession = async_sessionmaker(expire_on_commit=False)
AsyncSession.configure(bind=async_engine)


class Base(DeclarativeBase):
    pass


class Listing(Base):
    __tablename__ = "listing"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    slug: Mapped[str] = mapped_column(
        String(256), index=True, unique=True, nullable=False
    )
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )
