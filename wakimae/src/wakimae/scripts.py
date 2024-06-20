import asyncio
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def synchronize_user():
    await run_local_sync()
    await run_local_sync()
    await migrate_embeddings()


if __name__ == "__main__":
    # asyncio.run(run_local_sync())
    asyncio.run(a())

    pass
