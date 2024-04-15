import asyncio
import dataclasses
import datetime
from typing import Annotated, Any, Literal

import aiosqlite
from johen.examples import Examples
from johen.generators import specialized
from sqlalchemy import (Boolean, Connection, DateTime, ForeignKey, Index,
                        Integer, String, UniqueConstraint, select, text)
from sqlalchemy.dialects.sqlite import insert
from sqlalchemy.event import listen
from sqlalchemy.ext.asyncio import (AsyncAttrs, async_sessionmaker,
                                    create_async_engine)
from sqlalchemy.orm import DeclarativeBase, Mapped, Mapper, mapped_column

async_engine = create_async_engine("sqlite+aiosqlite:////var/sqlite/wakimae/app.db")
AsyncSession = async_sessionmaker(expire_on_commit=False)
AsyncSession.configure(bind=async_engine)


class Base(AsyncAttrs, DeclarativeBase):
    pass


emails = (f"{uuid.hex}@email.com" for uuid in specialized.uuids)


class User(Base):
    __tablename__ = "user"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    account_id: Mapped[Annotated[str, Examples(specialized.sha1s)]] = mapped_column(
        String(128), index=True, unique=True, nullable=False
    )
    email: Mapped[Annotated[str, Examples(emails)]] = mapped_column(
        String(128), index=True, unique=True, nullable=False
    )
    refresh_token: Mapped[Annotated[str, Examples(specialized.sha1s)]] = mapped_column(
        String(128), nullable=False
    )
    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow, nullable=False
    )


class SyncCursor(Base):
    __tablename__ = "sync_cursor"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    cursor: Mapped[str] = mapped_column(String(128), nullable=False, default="")
    namespace: Mapped[str] = mapped_column(
        String(128), nullable=False, server_default="dropbox:list_folder"
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)

    __table_args__ = (UniqueConstraint("user_id", "namespace"),)

    @classmethod
    async def find_from_user_namespace(
        cls, user_id: int, namespace: str
    ) -> "SyncCursor":
        async with AsyncSession() as session:
            result = await session.execute(
                select(SyncCursor).filter(
                    SyncCursor.user_id == user_id, SyncCursor.namespace == namespace
                )
            )
            row = result.scalar_one_or_none()
            if not row:
                return SyncCursor(user_id=user_id, namespace=namespace)
            return row

    async def update_cursor(self, value: str):
        async with AsyncSession() as session:
            await session.execute(
                insert(SyncCursor)
                .values(
                    user_id=self.user_id,
                    cursor=value,
                    namespace=self.namespace,
                )
                .on_conflict_do_update(
                    index_elements=("user_id", "namespace"),
                    set_=dict(cursor=value),
                )
            )
            await session.commit()


class File(Base):
    __tablename__ = "file"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    content_hash: Mapped[Annotated[str, Examples(specialized.sha1s)]] = mapped_column(
        String(64), nullable=False, index=True
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)
    pending_edits: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    deleted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    path: Mapped[Annotated[str, Examples(specialized.file_paths)]] = mapped_column(
        String(256), nullable=False
    )
    rev: Mapped[Annotated[str, Examples(specialized.sha1s)]] = mapped_column(
        String(128), nullable=False
    )
    sequence: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0", index=True
    )

    def __repr__(self) -> str:
        return f"<File {self.id} path={self.path} pending_edits={self.pending_edits} content_hash={self.content_hash} user_id={self.user_id} rev={self.rev}>"

    __table_args__ = (
        UniqueConstraint("user_id", "path"),
        Index("file_sequence", "user_id", "sequence"),
    )


class Scheduled(Base):
    __tablename__ = "scheduled"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    file_id: Mapped[int] = mapped_column(
        ForeignKey("file.id"), nullable=False, unique=True
    )
    schedule: Mapped[int] = mapped_column(Integer, nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), nullable=False)

    __table_args__ = (Index("schedule_sequence", "user_id", "schedule"),)


@dataclasses.dataclass
class Trigger:
    name: str
    model: type[Base] | str
    timing: Literal["BEFORE", "AFTER"]
    verb: Literal["DELETE", "INSERT", "UPDATE"]
    statements: list[str] = dataclasses.field(default_factory=list)

    def __post_init__(self):
        if issubclass(self.model, Base):
            if self.model.__table__ is not None:
                listen(self.model.__table__, "after_create", self.handle_creation)

    def handle_creation(
        self, target: Any, connection: Connection, **kwargs: Any
    ) -> None:
        connection.execute(text(self.create()))

    @property
    def table(self) -> str:
        if isinstance(self.model, str):
            return self.model
        return self.model.__tablename__

    def create(self) -> str:
        return f"""
CREATE TRIGGER IF NOT EXISTS {self.name}
{self.timing} {self.verb} ON {self.table}
FOR EACH ROW BEGIN {'; '.join(self.statements)}; END
"""

    def delete(self) -> str:
        return f"DROP TRIGGER IF EXISTS {self.name}"


on_insert_file_update_sequence_trigger = Trigger(
    "on_insert_file_update_sequence",
    File,
    "AFTER",
    "INSERT",
)

on_insert_file_update_sequence_trigger.statements.append(
    f"UPDATE {File.__tablename__} SET sequence = (SELECT Max(sequence) + 1 FROM {File.__tablename__}) WHERE {File.__tablename__}.rowid = new.rowid"
)

on_update_file_update_sequence_trigger = dataclasses.replace(
    on_insert_file_update_sequence_trigger,
    verb="UPDATE",
    name="on_upsert_file_update_sequence_trigger",
)
