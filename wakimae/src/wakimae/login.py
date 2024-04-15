import dataclasses
import datetime
import logging
from typing import (Awaitable, Callable, Literal, NewType, NotRequired,
                    TypedDict, TypeVar)

import aiohttp
import pydantic
import pytest
from aiohttp import ClientResponseError
from nicegui import app, ui
from sqlalchemy import select
from sqlalchemy.dialects.sqlite import insert

from wakimae import components, config
from wakimae.db import AsyncSession, User
from wakimae.utils import submits_with

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

AccessToken = NewType("AccessToken", str)

_T = TypeVar("_T")


class TokenRequest(TypedDict):
    client_id: str
    client_secret: str
    grant_type: Literal["authorization_code", "refresh_token"]

    code: NotRequired[str]
    refresh_token: NotRequired[str]


class DropboxUser(pydantic.BaseModel):
    account_id: str
    disabled: bool
    email: str
    locale: str


class TokenAuthorizationResponse(pydantic.BaseModel):
    access_token: str
    account_id: str
    expires_in: int
    refresh_token: str


class TokenRefreshResponse(pydantic.BaseModel):
    access_token: str
    expires_in: int


def authorizatize_url():
    return (
        f"https://www.dropbox.com/oauth2/authorize?client_id={config.dropbox_app_key}&"
        f"response_type=code&token_access_type=offline"
    )


async def oauth_token(
    params: TokenRequest,
) -> TokenAuthorizationResponse | TokenRefreshResponse:
    async with aiohttp.ClientSession() as client:
        response = await client.post(
            "https://api.dropboxapi.com/oauth2/token",
            data=params,
        )

        response.raise_for_status()
        json_body = await response.json()

        if params["grant_type"] == "authorization_code":
            return TokenAuthorizationResponse.model_validate(json_body)
        return TokenRefreshResponse.model_validate(json_body)


async def do_authorize(authorization_code: str) -> TokenAuthorizationResponse:
    response = await oauth_token(
        {
            "code": authorization_code,
            "client_id": config.dropbox_app_key,
            "client_secret": config.dropbox_app_secret,
            "grant_type": "authorization_code",
        }
    )
    assert isinstance(
        response, TokenAuthorizationResponse
    ), f"Unexpected logic failure deserializing authorization"
    return response


async def do_refresh(refresh_token: str) -> TokenRefreshResponse:
    response = await oauth_token(
        {
            "refresh_token": refresh_token,
            "client_id": config.dropbox_app_key,
            "client_secret": config.dropbox_app_secret,
            "grant_type": "refresh_token",
        }
    )
    assert isinstance(
        response, TokenRefreshResponse
    ), f"Unexpected logic failure deserializing refresh token"
    return response


@pytest.mark.asyncio
async def test_do_refresh(a_user: User):
    refreshed = await do_refresh(a_user.refresh_token)
    assert refreshed.access_token
    assert refreshed.expires_in


async def get_current_account(access_token: AccessToken):
    async with aiohttp.ClientSession() as client:
        response = await client.post(
            "https://api.dropboxapi.com/2/users/get_current_account",
            headers={"Authorization": f"Bearer {access_token!s}", "Content-Type": ""},
        )
        response.raise_for_status()
        json_body = await response.json()

    return DropboxUser.model_validate(json_body)


@pytest.mark.asyncio
async def test_get_current_account():
    account = await get_current_account(AccessToken(config.dropbox_test_token))
    assert account.account_id
    assert account.email
    assert not account.disabled

    with pytest.raises(aiohttp.ClientResponseError):
        await get_current_account(AccessToken("Not a token"))


class UserSession(pydantic.BaseModel):
    account_id: str = ""
    email: str = ""
    access_token: AccessToken = AccessToken("")
    expires_at: datetime.datetime = datetime.datetime.utcnow()

    async def get_user(self) -> User | None:
        async with AsyncSession() as session:
            result = await session.execute(
                select(User).where(User.account_id == self.account_id)
            )
            return result.scalar_one_or_none()

    async def maybe_refresh(self) -> "UserSession | None":
        if self.expires_at < datetime.datetime.utcnow() - datetime.timedelta(minutes=5):
            user = await self.get_user()
            if not user:
                return None
            refresh_response = await do_refresh(user.refresh_token)
            return await complete_login(refresh_response)
        return self


async def complete_login(
    response: TokenAuthorizationResponse | TokenRefreshResponse,
) -> UserSession:
    access_token = AccessToken(response.access_token)
    user = await get_current_account(access_token)

    if isinstance(response, TokenAuthorizationResponse):
        async with AsyncSession() as session:
            await session.execute(
                insert(User)
                .values(
                    account_id=user.account_id,
                    email=user.email,
                    refresh_token=response.refresh_token,
                )
                .on_conflict_do_update(
                    index_elements=("account_id",),
                    set_=dict(
                        refresh_token=response.refresh_token,
                        updated_at=datetime.datetime.utcnow(),
                        email=user.email,
                    ),
                )
            )
            await session.commit()

    return UserSession(
        account_id=user.account_id,
        email=user.email,
        access_token=access_token,
        expires_at=datetime.datetime.utcnow()
        + datetime.timedelta(seconds=response.expires_in - 30),
    )


@pytest.mark.asyncio
async def test_complete_login(a_user: User):
    refreshed = await do_refresh(a_user.refresh_token)
    user_session_1 = await complete_login(refreshed)
    user_1 = await user_session_1.get_user()
    assert user_1

    user_session_2 = await complete_login(refreshed)
    user_2 = await user_session_1.get_user()
    assert user_2

    assert user_session_1.account_id == user_session_2.account_id
    assert user_1.id == user_2.id

    assert await complete_login(
        TokenRefreshResponse(
            access_token=AccessToken(config.dropbox_test_token), expires_in=10000
        )
    )


async def get_user_session() -> UserSession | None:
    if user_session_json := app.storage.user.get("user_session"):
        return await UserSession.model_validate(user_session_json).maybe_refresh()
    return None


def update_user_session(session: UserSession):
    app.storage.user["user_session"] = session.model_dump(mode="json")


def clear_user_session():
    app.storage.user["user_session"] = None


@pytest.mark.asyncio
async def test_user_session():
    clear_user_session()
    user_session = await complete_login(
        TokenRefreshResponse(
            access_token=AccessToken(config.dropbox_test_token), expires_in=10000
        )
    )
    update_user_session(user_session)
    assert await get_user_session()


@ui.refreshable
def show_submit_authorization_code(has_error=False):
    auth_code = ui.input(
        label="Authorization Code",
        placeholder="paste your authorization",
        validation={"Authorization Failed": lambda value: not has_error or value},
    ).classes("w-full")
    auth_code.validate()
    submit_button = ui.button("Submit")

    @submits_with(auth_code, submit_button)
    async def submit():
        try:
            auth_response = await do_authorize(auth_code.value)
            user_session = await complete_login(auth_response)
            update_user_session(user_session)

            if redirect_to := app.storage.browser.get("redirect_to"):
                ui.open(redirect_to)
            else:
                ui.open("/")
        except ClientResponseError as e:
            logger.exception("Failed auth", exc_info=e)
            show_submit_authorization_code.refresh(has_error=True)
        except Exception as e:
            logger.exception("Unexpected exception", exc_info=e)
            show_submit_authorization_code.refresh(has_error=True)


@ui.page("/login")
def login():
    with components.main_column():
        with components.row():
            ui.label("弁").classes("text-7xl text-center w-full")

        with components.row():
            ui.label(
                "To complete login, complete authorization and copy the copy into the box below."
            )
            ui.link("Get Authorization Code", target=authorizatize_url(), new_tab=True)

        with components.row():
            show_submit_authorization_code()


async def start_root_user_session() -> UserSession:
    async with AsyncSession() as session:
        result = await session.execute(select(User).order_by(User.id).limit(1))
        user = result.scalar_one()
        refresh_response = await do_refresh(user.refresh_token)
        sess = await complete_login(refresh_response)
        return sess


@dataclasses.dataclass
class UserFactory:
    user: User

    async def save(self):
        async with AsyncSession() as session:
            session.add(self.user)
            await session.commit()
