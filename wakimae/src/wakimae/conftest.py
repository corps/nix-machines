import asyncio
import contextlib
import socket
import tempfile

import johen.generators.pydantic
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


async def _start_test_user_session() -> UserSession:
    account = await get_current_account(AccessToken(config.dropbox_test_token))
    return await complete_login(
        TokenAuthorizationResponse(
            access_token=config.dropbox_test_token,
            account_id=account.account_id,
            expires_in=10000000000,
            refresh_token="",
        )
    )


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


@pytest.fixture(autouse=True, scope="session")
def a_user() -> User:
    return asyncio.run(_select_a_user())


@pytest.fixture(autouse=True, scope="function")
def configure_test_db():
    with tempfile.NamedTemporaryFile(delete=False) as f:
        AsyncSession.configure(
            bind=create_async_engine(f"sqlite+aiosqlite:////{f.name}")
        )
    asyncio.run(init_models())


@pytest.fixture(autouse=True, scope="function")
def a_user_session(configure_test_db) -> UserSession:
    return asyncio.run(_start_test_user_session())


global_config["matchers"].append(johen.generators.pydantic.generate_pydantic_instances)


def find_free_port() -> int:
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


# pytest_plugins = ('pytest_asyncio',)
