import pytest

from libbiz.db import AsyncSession, Base, async_engine


@pytest.fixture(autouse=True, scope="session")
def configure_test_db():
    async_engine.url = "sqlite-aiosqlite:///:memory:"
    AsyncSession.configure(bind=async_engine)
    Base.metadata.create_all(async_engine.sync_engine)
