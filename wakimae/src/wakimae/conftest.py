import asyncio
import contextlib
import socket
import tempfile

import johen.generators.pydantic
import johen.generators.sqlalchemy
import pytest
from johen import global_config
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine

from wakimae import config
from wakimae.db import AsyncSession, Base, User, async_engine
from wakimae.login import (AccessToken, TokenAuthorizationResponse,
                           UserSession, complete_login, do_refresh,
                           get_current_account)


async def init_models():
    async with AsyncSession.kw["bind"].begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def _select_a_user() -> User:
    async with AsyncSession() as session:
        result = await session.execute(select(User).order_by(User.id).limit(1))
        user = result.scalar_one_or_none()
        assert user, "Log into a user to enable a testing user."
        return user


class MockedStorage:
    def __init__(self):
        self.user = {}


@pytest.fixture(scope="function", autouse=True)
def mock_storage():
    from nicegui import app

    original_storage = app.storage
    app.storage = MockedStorage()
    try:
        yield
    finally:
        app.storage = original_storage


@pytest.fixture(scope="session")
def a_user() -> User:
    return asyncio.run(_select_a_user())


@pytest.fixture(autouse=True, scope="function")
def configure_test_db():
    with tempfile.NamedTemporaryFile(delete=False) as f:
        AsyncSession.configure(
            bind=create_async_engine(f"sqlite+aiosqlite:////{f.name}")
        )
    asyncio.run(init_models())


global_config["matchers"].append(johen.generators.pydantic.generate_pydantic_instances)
global_config["matchers"].append(
    johen.generators.sqlalchemy.generate_sqlalchemy_instance
)


def find_free_port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


# pytest_plugins = ('pytest_asyncio',)
