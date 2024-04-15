import asyncio
import logging
import os.path
import time
import uuid

from sqlalchemy import select

from wakimae import config
from wakimae.db import AsyncSession, File
from wakimae.legacy import LegacyClozeType, LegacyNote, LegacyTerm, parse_note
from wakimae.login import UserSession, start_root_user_session
from wakimae.schedule import Minutes, StudyCloze, StudyItem, is_study_item
from wakimae.search import UserVectorStore, synchronize_user_vector_store
from wakimae.store import Store
from wakimae.sync import do_sync

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def load_legacy(session: UserSession):
    user = await session.get_user()
    assert user

    store = Store(user, config.store_prefix)
    notes: list[LegacyNote] = []

    async for batch, cursor in store.file_batches(""):
        for file in batch:
            if file.path.endswith(".txt"):
                with open(store.content_path(file), "rb") as f:
                    decoded = f.read().decode()
                    next_note = parse_note(decoded)
                    notes.append(next_note)

    return notes


async def convert_notes():
    session = await start_root_user_session()
    user = await session.get_user()
    assert user
    store = Store(user)
    notes = await load_legacy(session)

    for note in notes:
        si = StudyItem(
            path=f"/wakimae/{uuid.uuid4().hex}.json",
        )
        logger.info(f"Converting note")

        content = note.attributes.content
        term_setups: list[tuple[int, LegacyTerm]] = []
        for term in note.attributes.terms:
            try:
                start_idx = content.index(term.attributes.marker)
                term_setups.append((start_idx, term))
            except ValueError:
                pass

        term_setups.sort(key=lambda t: t[0])

        for _, term in term_setups:
            for cloze in term.attributes.clozes:
                start_idx = content.index(term.attributes.marker)
                content = content.replace(
                    term.attributes.marker, term.attributes.marker
                )

                if cloze.attributes.type in {
                    LegacyClozeType.PRODUCE,
                    LegacyClozeType.RECOGNIZE,
                }:
                    si.clozes.append(
                        StudyCloze(
                            definition=term.attributes.definition,
                            cloze_start=start_idx,
                            cloze_end=start_idx + len(term.attributes.marker),
                        )
                    )
                    si.last_answered = Minutes(
                        cloze.attributes.schedule.lastAnsweredMinutes
                    )
                    si.due_minutes = Minutes(cloze.attributes.schedule.nextDueMinutes)
                    si.interval_minutes = Minutes(
                        cloze.attributes.schedule.intervalMinutes
                    )
                    break

        if not si.clozes:
            logger.info("Skipping")
            continue
        si.content = content
        async with store.store_local_edit(si.path) as f:
            logger.info("Dumping file.")
            f.write(si.model_dump_json().encode("utf-8"))


async def run_local_sync():
    logging.info("Starting up.")
    session = await start_root_user_session()
    await do_sync(session)
    logging.info("Sync completed.")


async def migrate_embeddings():
    session = await start_root_user_session()
    user = await session.get_user()
    assert user
    await synchronize_user_vector_store(user)


async def fix_files():
    session = await start_root_user_session()
    user = await session.get_user()
    assert user
    store = Store(user)

    async for batch, cursor in store.file_batches(""):
        print(cursor)
        for file in batch:
            if is_study_item(file.path):
                file.deleted = True
                file.pending_edits = True
                await store.mark_user_file(file)


async def synchronize_user():
    await run_local_sync()
    await run_local_sync()
    await migrate_embeddings()


if __name__ == "__main__":
    # asyncio.run(run_local_sync())
    asyncio.run(synchronize_user())

    pass
