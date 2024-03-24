from johen import pytest

from libbiz.db import AsyncSession, async_engine


@pytest.fixture(autouse=True, scope="session")
def configure_test_db():
    async_engine.url = "sqlite:///:memory:"
    AsyncSession.configure(bind=async_engine)
