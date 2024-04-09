import asyncio
import logging
import time

from wakimae import config
from wakimae.legacy import LegacyNote, parse_note
from wakimae.login import start_root_user_session
from wakimae.store import Store
from wakimae.sync import do_sync

logging.basicConfig(level=logging.INFO)


async def load_legacy():
    session = await start_root_user_session()
    user = await session.get_user()
    assert user

    store = Store(user, config.store_prefix)
    all_file_paths = await store.list_files()
    notes: list[LegacyNote] = []

    for path in all_file_paths:
        if path.endswith(".txt"):
            result = await store.read_file(path)
            if not result:
                continue

            file, path = result
            with open(path, "rb") as f:
                decoded = f.read().decode()
                notes.append(parse_note(decoded))

    return notes


async def run_local_sync():
    logging.info("Starting up.")
    session = await start_root_user_session()
    await do_sync(session)
    logging.info("Sync completed.")


if __name__ == "__main__":
    # asyncio.run(run_local_sync())
    asyncio.run(load_legacy())
