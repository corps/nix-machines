import asyncio
import contextlib
import dataclasses
import hashlib
import logging
import os
import shutil
import tempfile
from typing import IO, Any, AsyncIterator

import pytest
from johen import generate
from johen.generators import specialized
from johen.pytest import parametrize
from sqlalchemy import or_, select, update
from wakimae import config
from wakimae.db import AsyncSession, File, User
from wakimae.login import UserFactory


@dataclasses.dataclass
class Store:
    user: User
    store_prefix: str = dataclasses.field(default_factory=lambda: config.store_prefix)

    async def get_edited_files(self) -> list[File]:
        async with AsyncSession() as session:
            result = await session.execute(
                select(File).filter(
                    File.user_id == self.user.id, File.pending_edits == True
                )
            )
            return list(result.scalars())

    async def mark_file_uploaded(self, file: File) -> None:
        async with AsyncSession() as session:
            await session.execute(
                update(File)
                .filter(
                    File.id == file.id,
                    File.user_id == self.user.id,
                    File.sequence == file.sequence,
                )
                .values(pending_edits=False)
            )
            await session.commit()

    def check_content_path(self, content_hash: str) -> str | None:
        path = os.path.join(self.store_prefix, content_hash)
        if os.path.isfile(path):
            return path
        return None

    async def find_file_by_path(self, path: str) -> File | None:
        async with AsyncSession() as session:
            result = await session.execute(
                select(File).filter(File.path == path, File.user_id == self.user.id)
            )
            file = result.scalar_one_or_none()
            if not file or file.deleted:
                return None
            return file

    async def delete_path(self, path: str, edit: bool):
        async with AsyncSession() as session:
            await session.execute(
                update(File)
                .filter(
                    File.user_id == self.user.id,
                    or_(File.path == path, File.path.startswith(path + "/")),
                )
                .values(pending_edits=edit, deleted=True)
            )
            await session.commit()

    async def mark_user_file(
        self,
        file: File,
    ) -> File:
        if file.path.lower() != file.path:
            raise ValueError(
                f"File {file.path} must contain only lowercase characters."
            )

        async with AsyncSession() as session:
            if file.id is not None:
                assert file.user_id == self.user.id
                file = await session.merge(file)
            file.user_id = self.user.id
            session.add(file)
            await session.commit()
            return file

    async def store_file(self, local_path: str) -> str:
        content_hash = await asyncio.get_running_loop().run_in_executor(
            None, lambda: content_hash_of(local_path)
        )
        shutil.move(local_path, os.path.join(self.store_prefix, content_hash))
        return content_hash

    def store_local_edit(self, path: str) -> "LocalFileSaveContextManager":
        return LocalFileSaveContextManager(self, path)

    async def file_batches(
        self, sequence_cursor: str, batch_size: int = 100
    ) -> AsyncIterator[tuple[list[File], str]]:
        sequence_num = -1 if not sequence_cursor else int(sequence_cursor)
        while True:
            async with AsyncSession() as session:
                result = await session.execute(
                    select(File)
                    .filter(File.user_id == self.user.id, File.sequence > sequence_num)
                    .order_by(File.sequence)
                    .limit(batch_size)
                )
                files = list(result.scalars())
            try:
                sequence_num = max([f.sequence for f in files])
            except ValueError:
                break
            yield files, str(sequence_num)

    def content_path(self, file: File) -> str:
        return os.path.join(self.store_prefix, file.content_hash)


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
@parametrize(count=1)
async def test_content_hash_of(user: User):
    async with AsyncSession() as session:
        session.add(user)
        await session.commit()
    store = Store(user)
    async with store.store_local_edit("/a") as f:
        f.write(b"word" * 8 * 1024 * 1024)
        f.flush()
        assert (
            content_hash_of(f.name)
            == "f9d2833923ee97ee314c5a6c9e972d4344156900276838d624ca6cee053d23a0"
        )


@dataclasses.dataclass
class StoreFactory:
    user_factory: UserFactory

    async def save(self):
        await self.user_factory.save()

    @property
    def user(self):
        return self.user_factory.user

    @property
    def store(self) -> Store:
        return Store(self.user)

    def generate_file(self, path_override: str | None = None):
        for file in generate(File):
            file.user_id = self.user.id
            if path_override:
                file.path = path_override
            return file


@pytest.mark.asyncio
@parametrize(count=1)
async def test_edit_state(
    store1: StoreFactory,
    store2: StoreFactory,
    common_path: specialized.FilePath,
    store_1_paths: tuple[specialized.FilePath, specialized.FilePath],
    store_2_paths: tuple[specialized.FilePath, specialized.FilePath],
):
    await store1.save()
    await store2.save()

    assert await store1.store.get_edited_files() == []
    assert await store2.store.get_edited_files() == []

    store1_unique_files = [store1.generate_file(path) for path in store_1_paths]
    store2_unique_files = [store2.generate_file(path) for path in store_2_paths]
    store1_common_file = store1.generate_file(common_path)
    store2_common_file = store1.generate_file(common_path)

    for file in [*store1_unique_files, store1_common_file]:
        file.pending_edits = True
        await store1.store.mark_user_file(file)

    for file in [*store2_unique_files, store2_common_file]:
        file.pending_edits = True
        await store2.store.mark_user_file(file)

    assert set(f.path for f in await store1.store.get_edited_files()) == {
        *store_1_paths,
        common_path,
    }
    assert set(f.path for f in await store2.store.get_edited_files()) == {
        *store_2_paths,
        common_path,
    }

    await store1.store.mark_file_uploaded(store1_unique_files[0])
    # Simultaneous load, so it won't actually mark it.
    assert set(f.path for f in await store1.store.get_edited_files()) == {
        *store_1_paths,
        common_path,
    }

    async with AsyncSession() as session:
        await store1.store.mark_file_uploaded(
            await session.scalar(
                select(File).where(File.id == store1_unique_files[0].id)
            )
        )
    assert set(f.path for f in await store1.store.get_edited_files()) == {
        *store_1_paths[1:],
        common_path,
    }

    await store2.store.delete_path(common_path, False)
    assert set(f.path for f in await store1.store.get_edited_files()) == {
        *store_1_paths[1:],
        common_path,
    }
    assert set(f.path for f in await store2.store.get_edited_files()) == {
        *store_2_paths
    }

    await store2.store.delete_path(common_path, True)
    assert set(f.path for f in await store2.store.get_edited_files()) == {
        *store_2_paths,
        common_path,
    }


@pytest.mark.asyncio
async def test_store():
    async with AsyncSession() as session:
        user = User(account_id="user1", email="you1@thing.com", refresh_token="")
        user2 = User(account_id="user2", email="you2@thing.com", refresh_token="")
        session.add(user)
        session.add(user2)
        await session.commit()

    with tempfile.TemporaryDirectory() as tempdir:
        store = Store(user, tempdir)
        store2 = Store(user2, tempdir)

        assert not await store.find_file_by_path("/a-file.txt")
        assert await store.get_edited_files() == []

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file = await store.mark_user_file(
                File(
                    content_hash=content_hash,
                    path="/a-file.txt",
                    rev="",
                    pending_edits=True,
                )
            )

        assert file.content_hash == content_hash
        assert file.rev == ""

        assert [f.id for f in await store.get_edited_files()] == [file.id]
        assert await store2.get_edited_files() == []
        assert not await store2.find_file_by_path("/a-file.txt")

        file = await store.find_file_by_path("/a-file.txt")
        assert file

        with open(store.content_path(file), "rb") as f:
            assert f.read() == b"test-content"

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content-2")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file2 = await store2.mark_user_file(
                File(
                    content_hash=content_hash,
                    path="/a-file.txt",
                    rev="rev",
                    pending_edits=False,
                )
            )

        assert file2.rev == "rev"

        assert [f.id for f in await store.get_edited_files()] == [file.id]
        assert [f.id for f in await store2.get_edited_files()] == []

        file = await store2.find_file_by_path("/a-file.txt")
        assert file

        with open(store2.content_path(file), "rb") as f:
            assert f.read() == b"test-content-2"

        with tempfile.NamedTemporaryFile(delete=False) as nf:
            nf.write(b"test-content-3")
            nf.flush()
            content_hash = await store.store_file(nf.name)
            file2 = await store2.mark_user_file(
                File(
                    content_hash=content_hash,
                    path="/a-file.txt",
                    rev="new-rev",
                    pending_edits=True,
                )
            )

        assert [f.id for f in await store2.get_edited_files()] == [file2.id]
        assert file2.rev == "new-rev"
        file = await store2.find_file_by_path("/a-file.txt")

        with open(store2.content_path(file), "rb") as f:
            assert f.read() == b"test-content-3"


@pytest.mark.asyncio
@parametrize(count=1)
async def test_sequences(
    store_factory: StoreFactory,
):
    await store_factory.save()
    async with AsyncSession() as session:
        for i in range(10):
            file = store_factory.generate_file()
            session.add(file)
        await session.commit()

    cursors = []
    file_ids = set()
    async for batch, cursor in store_factory.store.file_batches("", batch_size=2):
        assert len(batch) == 2
        for file in batch:
            assert file.id not in file_ids
            file_ids.add(file.id)
        cursors.append(cursor)

    assert len(cursors) == 5
    assert (
        len(
            [
                0
                async for _ in store_factory.store.file_batches(
                    cursors[2], batch_size=2
                )
            ]
        )
        == 2
    )
    assert (
        len(
            [
                0
                async for _ in store_factory.store.file_batches(
                    cursors[-1], batch_size=2
                )
            ]
        )
        == 0
    )


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
        if rv:
            logging.info("RV was %r", rv)
            return rv

        content_hash = await self.store.store_file(self.local_file)

        target_file = await self.store.find_file_by_path(self.target_path)
        if target_file is None:
            target_file = File(
                user_id=self.store.user.id,
                rev="",
                path=self.target_path,
                deleted=False,
            )
        target_file.pending_edits = True
        target_file.content_hash = content_hash

        await self.store.mark_user_file(target_file)
        return None
