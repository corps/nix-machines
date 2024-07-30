import asyncio
import dataclasses
import functools
import json
import logging
import tempfile
from typing import Any, Awaitable, Callable, Literal, ParamSpec, TypeVar, cast

import aiohttp
import pydantic
import pytest
from sqlalchemy import select
from sqlalchemy.dialects.sqlite import insert

from wakimae import config
from wakimae.db import AsyncSession, File, SyncCursor
from wakimae.login import UserSession
from wakimae.store import Store, content_hash_of
from wakimae.utils import concurrently_run

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


class FileMetadata(pydantic.BaseModel):
    path_lower: str
    rev: str
    size: int
    id: str
    content_hash: str
    tag: Literal["file"] = pydantic.Field(alias=".tag", default="file")


class FolderMetadata(pydantic.BaseModel):
    path_lower: str
    id: str
    tag: Literal["folder"] = pydantic.Field(alias=".tag", default="folder")


class DeletedMetadata(pydantic.BaseModel):
    path_lower: str
    tag: Literal["deleted"] = pydantic.Field(alias=".tag", default="deleted")


class ListFolderResult(pydantic.BaseModel):
    cursor: str
    entries: list[FileMetadata | FolderMetadata | DeletedMetadata]
    has_more: bool


# _P = ParamSpec('_P')
# _R = TypeVar('_R')
_C = TypeVar("_C", bound=Callable[..., Awaitable])


def rate_limited(method: _C) -> _C:
    @functools.wraps(method)
    async def wrapper(*args, **kwargs):
        for _ in range(5):
            try:
                result = await method(*args, **kwargs)
                return result
            except aiohttp.ClientResponseError as e:
                if e.status == 429:
                    if "Retry-After" in e.headers:
                        logger.info(f'Retrying after {e.headers["Retry-After"]}')
                        await asyncio.sleep(int(e.headers["Retry-After"]))
                        continue
                raise e

    return cast(Any, wrapper)


@dataclasses.dataclass
class SyncClient:
    client_session: aiohttp.ClientSession
    user_session: UserSession

    @rate_limited
    async def resolve_file(self, path: str) -> FileMetadata | None:
        async with self.client_session.post(
            "https://api.dropboxapi.com/2/files/get_metadata",
            headers={"Authorization": f"Bearer {self.user_session.access_token}"},
            json=dict(include_deleted=True, path=path),
        ) as response:
            if response.status == 409:
                return None

            response.raise_for_status()
            json_body = await response.json()
            if json_body[".tag"] != "file":
                return None

            return FileMetadata.model_validate(json_body)

    @rate_limited
    async def delete_file(self, remote_path: str, rev: str) -> bool:
        if not rev:
            return False

        async with self.client_session.post(
            "https://api.dropboxapi.com/2/files/delete_v2",
            headers={"Authorization": f"Bearer {self.user_session.access_token}"},
            json=dict(path=remote_path, parent_rev=rev),
        ) as response:
            if response.status == 409:
                return False

            response.raise_for_status()
            return True

    @rate_limited
    async def upload_file(
        self, remote_path: str, local_path: str, rev: str, content_hash: str
    ) -> FileMetadata | Literal["conflict"]:
        with open(local_path, "rb") as data:
            async with self.client_session.post(
                "https://content.dropboxapi.com/2/files/upload",
                headers={
                    "Authorization": f"Bearer {self.user_session.access_token}",
                    "Dropbox-API-Arg": json.dumps(
                        dict(
                            path=remote_path,
                            autorename=False,
                            strict_conflict=True,
                            content_hash=content_hash,
                            mode=(
                                {".tag": "update", "update": rev}
                                if rev
                                else {".tag": "add"}
                            ),
                        )
                    ),
                    "Content-Type": "application/octet-stream",
                },
                data=data,
            ) as response:
                if response.status == 409:
                    return "conflict"

                response.raise_for_status()

                json_body = await response.json()
                return FileMetadata.model_validate(json_body)

    @rate_limited
    async def download_file(self, path: str, rev: str) -> tuple[FileMetadata, str]:
        async with self.client_session.post(
            "https://content.dropboxapi.com/2/files/download",
            headers={
                "Authorization": f"Bearer {self.user_session.access_token}",
                "Dropbox-API-Arg": json.dumps(dict(path=path, rev=rev)),
            },
            data="",
        ) as response:
            meta = FileMetadata.model_validate_json(
                response.headers["Dropbox-API-Result"]
            )
            with tempfile.NamedTemporaryFile(delete=False) as f:
                async for data in response.content.iter_chunked(1024):
                    f.write(data)
                f.flush()
                return meta, f.name

    @rate_limited
    async def list_folder(self, cursor: str, path: str = "") -> ListFolderResult:
        if not cursor:
            async with self.client_session.post(
                "https://api.dropboxapi.com/2/files/list_folder",
                headers={
                    "Authorization": f"Bearer {self.user_session.access_token}",
                },
                json=dict(
                    recursive=True,
                    include_deleted=True,
                    limit=50,
                    path=path,
                    include_non_downloadable_files=False,
                ),
            ) as response:
                response.raise_for_status()
                json_body = await response.json()
        else:
            async with self.client_session.post(
                "https://api.dropboxapi.com/2/files/list_folder/continue",
                headers={
                    "Authorization": f"Bearer {self.user_session.access_token}",
                },
                json=dict(cursor=cursor),
            ) as response:
                response.raise_for_status()
                json_body = await response.json()

        return ListFolderResult.model_validate(json_body)


async def do_sync(user_session: UserSession):
    user = await user_session.get_user()
    assert user
    async with aiohttp.ClientSession() as client_session:
        sync = SyncClient(client_session=client_session, user_session=user_session)
        store = Store(user=user, store_prefix=config.store_prefix)

        edited_files = await store.get_edited_files()

        for file in edited_files:
            if file.deleted:
                logger.info(f"Attempting delete of file {file.path}@rev={file.rev!r}")
                success = await sync.delete_file(file.path, file.rev)
                if not success:
                    logger.info("Conflict detected, will process on sync.")
            elif local_path := store.check_content_path(file.content_hash):
                logger.info(f"Uploading file {file.path}@rev={file.rev!r}")
                conflicted = await sync.upload_file(
                    file.path, local_path, file.rev, file.content_hash
                )
                if conflicted == "conflict":
                    logger.info("Conflict detected, will process on sync.")
            await store.mark_file_uploaded(file)

        while True:
            cursor = await SyncCursor.find_from_user_namespace(
                user.id, "dropbox:list_folder"
            )
            cursor_str = cursor.cursor

            logger.info(f"Syncing from cursor {cursor_str!r}...")
            list_folder = await sync.list_folder(cursor_str)

            download_metas: list[FileMetadata] = []
            mark_targets: list[FileMetadata] = []

            for entry in list_folder.entries:
                if isinstance(entry, FileMetadata):
                    if store.check_content_path(entry.content_hash):
                        mark_targets.append(entry)
                    else:
                        download_metas.append(entry)

                if isinstance(entry, DeletedMetadata):
                    logger.info(f"Deleting {entry.path_lower}...")
                    await store.delete_path(entry.path_lower, edit=False)

            for entry in download_metas:
                download_meta, local_path = await sync.download_file(
                    entry.path_lower, entry.rev
                )
                logger.info(f"Downloading {download_meta.path_lower}...")
                await store.store_file(local_path)
                mark_targets.append(download_meta)

            for meta in mark_targets:
                existing_by_path = await store.find_file_by_path(meta.path_lower)
                if existing_by_path is not None:
                    file = existing_by_path
                else:
                    file = File(
                        path=meta.path_lower,
                    )

                file.content_hash = meta.content_hash
                file.rev = meta.rev
                file.pending_edits = False
                file.deleted = False

                await store.mark_user_file(file)

            logger.info(f"Updating cursor to {list_folder.cursor}")
            await cursor.update_cursor(list_folder.cursor)

            if not list_folder.has_more:
                logger.info("Done")
                break


@pytest.mark.asyncio
async def test_file_operations(a_user_session: UserSession):
    # user = await a_user_session.get_user()
    async with aiohttp.ClientSession() as session:
        sync = SyncClient(client_session=session, user_session=a_user_session)
        # testing a 404
        assert await sync.resolve_file("/not-a-file") is None

        # Clear state
        some_file = await sync.resolve_file("/some-file.txt")
        if some_file is not None:
            assert await sync.delete_file("/some-file.txt", rev=some_file.rev)

        # testing uploads
        with tempfile.NamedTemporaryFile() as f:
            f.write(b"test")
            f.flush()

            content_hash = content_hash_of(f.name)

            uploaded = await sync.upload_file(
                "/some-file.txt", f.name, "", content_hash
            )
            assert isinstance(uploaded, FileMetadata)
            assert uploaded.path_lower == "/some-file.txt"

            assert (
                await sync.upload_file("/some-file.txt", f.name, "", content_hash)
                == "conflict"
            )

        # testing downloads
        downloaded = 0
        meta, local_path = await sync.download_file(uploaded.path_lower, uploaded.rev)
        assert meta.content_hash == content_hash
        with open(local_path, "r") as f:
            assert f.read() == "test"
        downloaded += 1
        assert downloaded == 1

        assert sync.resolve_file("/some-file.txt")
        assert await sync.delete_file("/some-file.txt", uploaded.rev)
        assert not await sync.resolve_file("/some-file.txt")
        assert not await sync.delete_file("/some-file.txt", uploaded.rev)
