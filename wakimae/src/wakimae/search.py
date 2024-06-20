import asyncio
import contextlib
import dataclasses
import logging
import os.path
from functools import cached_property
from typing import Any

import aiosqlite
import numpy as np
import sqlite_vss
from fastembed import TextEmbedding

from wakimae import config
from wakimae.db import SyncCursor, User
from wakimae.schedule import StudyItem, is_study_item
from wakimae.store import Store

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


@dataclasses.dataclass
class UserVectorStore:
    user: User
    model_name: str = "intfloat/multilingual-e5-large"
    store_root: str = dataclasses.field(default_factory=lambda: config.store_prefix)

    @property
    def user_vector_db_path(self):
        return os.path.join(
            self.store_root, f"user_{self.user.id}_{self.model}_vectors.db"
        )

    def prepare_db(self) -> "PrepareDb":
        return PrepareDb(self.user_vector_db_path)

    async def find_related(
        self, content: str, num: int
    ) -> list[tuple[int, str, float]]:
        (embedding,) = await self.create_embedding([content])
        async with self.prepare_db() as db:
            distance_of_row_ids = {
                row["rowid"]: row["distance"]
                for row in await db.execute_fetchall(
                    "select rowid, distance from vss_vectors where vss_search(content_embedding, ?) limit ?;",
                    (embedding, num),
                )
            }
            return [
                (row["file_id"], row["content"], distance_of_row_ids[row["rowid"]])
                for row in await db.execute_fetchall(
                    "select row_id, file_id, content FROM contents where rowid in ?",
                    [distance_of_row_ids.keys()],
                )
            ]

    async def create_embedding(self, content: list[str]) -> list[np.ndarray]:
        def _inner() -> list[np.ndarray]:
            return list(self.model.embed(content))

        return await asyncio.get_running_loop().run_in_executor(None, _inner)

    async def updated_with_content(self, file_id: int, contents: list[str]):
        embeddings = await self.create_embedding(contents)

    @cached_property
    def model(self):
        return TextEmbedding(model_name=self.model_name)


async def synchronize_user_vector_store(user: User):
    store = Store(user)
    vector_store = UserVectorStore(user)

    sync_cursor = await SyncCursor.find_from_user_namespace(
        user.id, f"vector_store:{vector_store.model_name}:v2"
    )
    async for batch, cursor in store.file_batches(sync_cursor.cursor, batch_size=100):
        for file in batch:
            if not is_study_item(file.path):
                continue

            logger.info(f"Embedding for {file.path}")
            if file.deleted:
                await vector_store.updated_with_content(file.id, [])
                continue

            with open(os.path.join(store.store_prefix, file.content_hash), "rb") as f:
                study_item = StudyItem.model_validate_json(f.read())
                await vector_store.updated_with_content(
                    file.id, list(study_item.search_chunks())
                )

        logger.info(f"Updating cursor {cursor}")
        await sync_cursor.update_cursor(cursor)
