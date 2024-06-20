import asyncio
import dataclasses
import enum
from asyncio import Future, Task
from functools import cached_property
from typing import Any, Coroutine, TypeVar

from nicegui import Client

from wakimae.db import User
from wakimae.login import UserSession
from wakimae.search import UserVectorStore, synchronize_user_vector_store
from wakimae.sync import do_sync

_A = TypeVar("_A")


class Location(enum.Enum):
    MAIN = enum.auto()


@dataclasses.dataclass
class UserState:
    user: User
    user_session: UserSession
    client: Client
    is_syncing: bool = False
    location: Location = Location.MAIN
    shutdown: asyncio.Event = dataclasses.field(default_factory=asyncio.Event)
    sync_state_change: asyncio.Condition = dataclasses.field(
        default_factory=asyncio.Condition
    )
    sync_task: asyncio.Task | None = None

    @cached_property
    def vector_store(self) -> UserVectorStore:
        return UserVectorStore(self.user)

    def start_sync(self):
        if self.sync_task is not None:
            self.sync_task.cancel()
        self.sync_task = asyncio.create_task(self._run_sync())

    async def await_shutdown(self):
        await self.client.disconnected(check_interval=5.0)
        self.shutdown.set()

    async def _run_sync(self):
        self.is_syncing = True
        self.sync_state_change.notify_all()
        try:
            await self.run_or_end(do_sync(self.user_session))
            await self.run_or_end(synchronize_user_vector_store(self.user))
        finally:
            self.is_syncing = False
            self.sync_state_change.notify_all()

    async def run_or_end(
        self, c: Future[_A] | Coroutine[Any, Any, _A]
    ) -> tuple[_A] | None:
        if self.shutdown.is_set():
            return None

        end_task = asyncio.create_task(self.shutdown.wait())
        task: Future[_A] | Task[_A]
        if not isinstance(c, Future):
            task = asyncio.create_task(c)
        else:
            task = c
        parts: list[Future | Task] = [end_task, task]
        await asyncio.wait(parts, return_when=asyncio.FIRST_COMPLETED)
        if end_task.done():
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)
            return None
        else:
            end_task.cancel()
        if exc := task.exception():
            raise exc
        return (task.result(),)
