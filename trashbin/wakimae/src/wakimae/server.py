import asyncio

import sentry_sdk
from nicegui import Client, run, ui
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
    asyncio.create_task(user_state.await_shutdown())  # noqa

    async def notify_sync_state():
        while not user_state.shutdown.is_set():
            await user_state.run_or_end(user_state.sync_state_change.wait())
            if user_state.shutdown.is_set():
                return

            if user_state.is_syncing:
                ui.notify("Syncing starting...")

            if user_state.is_syncing:
                ui.notify("Syncing done.")

    asyncio.create_task(notify_sync_state())  # noqa
    user_state.start_sync()

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
