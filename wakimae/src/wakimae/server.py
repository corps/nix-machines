import sentry_sdk
from nicegui import ui

import wakimae.login  # noqa
from wakimae import config
from wakimae.components import main_column

with main_column():
    pass


if __name__ in {"__main__", "__mp_main__"}:
    import logging

    logging.root.setLevel(logging.DEBUG)
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
