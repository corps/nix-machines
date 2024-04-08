import asyncio
import contextlib
import dataclasses
import hashlib
import os
import shutil
import tempfile
import uuid
from typing import IO, Any

import pytest
from sqlalchemy import select, update
from sqlalchemy.dialects.sqlite import insert

from wakimae.db import AsyncSession, File, Tombstone, User
from wakimae.login import UserSession


@dataclasses.dataclass
class Store:
    user: User
    store_prefix: str

    async def get_deleted_files(self) -> list[Tombstone]:
        async with AsyncSession() as session:
            result = await session.execute(
                select(Tombstone).filter(Tombstone.user_id == self.user.id)
            )
            return list(result.scalars())

    async def get_edited_files(self) -> list[File]:
        async with AsyncSession() as session:
            result = await session.execute(
                select(File).filter(
                    File.user_id == self.user.id, File.pending_edits == 1
                )
            )
            return list(result.scalars())

    async def mark_file_uploaded(self, file: File) -> None:
        async with AsyncSession() as session:
            await session.execute(
                update(File)
                .filter(
                    File.user_id == self.user.id,
                    File.pending_edits == 1,
                    File.id == file.id,
                    File.content_hash == file.content_hash,
                )
                .values(pending_edits=0)
            )
            await session.commit()

    async def mark_tombstone_applied(self, tombstone: Tombstone) -> None:
        async with AsyncSession() as session:
            await session.delete(tombstone)
            await session.commit()

    def check_content_path(self, content_hash: str) -> str | None:
        path = os.path.join(self.store_prefix, content_hash)
        if os.path.isfile(path):
            return path
        return None

    async def list_files(self) -> list[str]:
        async with AsyncSession() as session:
            result = await session.execute(
                select(File.path).filter(File.user_id == self.user.id)
            )
            return result.scalars()

    async def read_file(self, path: str) -> tuple[File, str] | None:
        async with AsyncSession() as session:
            result = await session.execute(
                select(File).filter(File.path == path, File.user_id == self.user.id)
            )
            file = result.scalar_one_or_none()
            if not file:
                return None
            return file, os.path.join(self.store_prefix, file.content_hash)

    async def delete_path(self, path: str, edit: bool):
        async with AsyncSession() as session:
            criteria = (
                File.path.startswith(path) if path.endswith("/") else File.path == path
            )
            result = await session.execute(
                select(File).filter(criteria, File.user_id == self.user.id)
            )
            for file in result.scalars():
                await session.delete(file)
                if edit:
                    session.add(
                        Tombstone(
                            user_id=file.user_id,
                            external_id=file.external_id,
                            path=file.path,
                            rev=file.rev,
                        )
                    )
            await session.commit()

    async def mark_user_file(
        self,
        content_hash: str,
        remote_path: str,
        external_id: str,
        rev: str,
        edit: bool,
    ) -> File:
        async with AsyncSession() as session:
            await session.execute(
                insert(File)
                .values(
                    content_hash=content_hash,
                    user_id=self.user.id,
                    external_id=external_id,
                    path=remote_path,
                    pending_edits=1 if edit else 0,
                    rev=rev,
                )
                .on_conflict_do_update(
                    index_elements=("user_id", "path"),
                    set_=dict(
                        content_hash=content_hash,
                        rev=rev,
                        pending_edits=1 if edit else 0,
                        external_id=external_id,
                    ),
                )
            )
            await session.commit()

            result = await session.execute(
                select(File).filter(
                    File.user_id == self.user.id, File.path == remote_path
                )
            )
            return result.scalar_one()

    async def store_file(self, local_path: str) -> str:
        content_hash = await asyncio.get_running_loop().run_in_executor(
            None, lambda: content_hash_of(local_path)
        )
        shutil.move(local_path, os.path.join(self.store_prefix, content_hash))
        return content_hash

    def store_local_edit(self, path: str) -> "LocalFileSaveContextManager":
        return LocalFileSaveContextManager(self, path)


def content_hash_of(filepath: str):
    with open(filepath, "rb") as f:
        block_hashes = b""
        while True:
            chunk = f.read(4 * 1024 * 1024)
            if not chunk:
                break
            block_hashes += hashlib.sha256(chunk).digest()
        return hashlib.sha256(block_hashes).hexdigest()


@pytest.mark.asyncio
async def test_store(a_user_session: UserSession):
    user = await a_user_session.get_user()
    assert user

    async with AsyncSession() as session:
        user2 = User(account_id="new_thing", email="you@thing.com", refresh_token="")
        session.add(user2)
        await session.commit()

    with tempfile.TemporaryDirectory() as tempdir:
        store = Store(user, tempdir)
        store2 = Store(user2, tempdir)

        assert not await store.read_file("/a-file.txt")
        assert await store.get_edited_files() == []

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file = await store.mark_user_file(
                content_hash, "/a-file.txt", f"some-id", "", True
            )

        assert file.content_hash == content_hash
        assert file.rev == ""

        assert [f.id for f in await store.get_edited_files()] == [file.id]
        assert await store2.get_edited_files() == []
        assert not await store2.read_file("/a-file.txt")

        result = await store.read_file("/a-file.txt")
        assert result
        file, path = result

        with open(path, "rb") as f:
            assert f.read() == b"test-content"

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content-2")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file2 = await store2.mark_user_file(
                content_hash, "/a-file.txt", f"some-id-2", "rev", False
            )

        assert file2.rev == "rev"

        assert [f.id for f in await store.get_edited_files()] == [file.id]
        assert [f.id for f in await store2.get_edited_files()] == []

        result = await store2.read_file("/a-file.txt")
        assert result
        file, path = result

        with open(path, "rb") as f:
            assert f.read() == b"test-content-2"

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content-3")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file2 = await store2.mark_user_file(
                content_hash, "/a-file.txt", "new-some-id", "new-rev", True
            )

        assert [f.id for f in await store2.get_edited_files()] == [file2.id]
        assert file2.rev == "new-rev"
        assert file2.external_id == "new-some-id"
        result = await store2.read_file("/a-file.txt")
        assert result
        file, path = result

        with open(path, "rb") as f:
            assert f.read() == b"test-content-3"


class LocalFileSaveContextManager(contextlib.AbstractAsyncContextManager):
    context: contextlib.ExitStack
    store: Store
    target_path: str
    local_file: str

    def __init__(self, store: Store, target_path: str):
        self.context = contextlib.ExitStack()
        self.store = store
        self.target_path = target_path
        self.context.__enter__()

    async def __aenter__(self) -> IO[bytes]:
        """Return `self` upon entering the runtime context."""
        f = self.context.enter_context(tempfile.NamedTemporaryFile(delete=False))
        self.local_file = f.name
        return f

    async def __aexit__(self, __exc_type: Any, __exc_value: Any, __traceback: Any):
        rv = self.context.__exit__(__exc_type, __exc_value, __traceback)
        if rv is not None:
            return rv

        result = await self.store.read_file(self.target_path)
        if result:
            target_file, _ = result
        else:
            target_file = File(external_id=uuid.uuid4().hex, rev="")

        content_hash = await self.store.store_file(self.local_file)
        await self.store.mark_user_file(
            content_hash,
            remote_path=self.target_path,
            external_id=target_file.external_id,
            rev=target_file.rev,
            edit=True,
        )
        return None
