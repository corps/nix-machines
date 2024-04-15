import sentry_sdk
from nicegui import Client, ui

from wakimae import config
from wakimae.login import get_user_session
from wakimae.main import main_page
from wakimae.state import Location, UserState


@ui.refreshable
async def navigation(state: UserState):
    if state.location == Location.MAIN:
        return await main_page(state)


@ui.page("/")
async def index(client: Client):
    await client.connected()
    user_session = await get_user_session()
    if not user_session:
        ui.open("/login")
        return

    user = await user_session.get_user()
    if user is None:
        ui.open("/login")
        return

    user_state = UserState(user=user, user_session=user_session, client=client)
    await navigation(user_state)


if __name__ in {"__main__", "__mp_main__"}:
    import logging

    logging.root.setLevel(logging.INFO)
    logging.root.addHandler(logging.StreamHandler())

    sentry_sdk.init(
        dsn=config.sentry_dsn,
        enable_tracing=True,
    )
    ui.run(
        title="wakimae",
        port=config.port,
        storage_secret=config.storage_secret,
    )
