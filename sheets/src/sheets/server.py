import os

import sentry_sdk
from nicegui import ui
from sentry_sdk.integrations.asyncio import AsyncioIntegration
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.starlette import StarletteIntegration

from sheets.views.sheet_view import sheet_page
from sheets.views.store_view import store_page
from sheets.views.study import study_page

ui.page("/")(store_page)
ui.page("/study")(study_page)
ui.page("/{ddb_id}")(sheet_page)


if __name__ in {"__main__", "__mp_main__"}:
    import logging

    logging.root.setLevel(logging.INFO)
    logging.root.addHandler(logging.StreamHandler())

    sentry_sdk.init(
        dsn=os.environ.get("SENTRY_DSN"),
        enable_tracing=True,
        integrations=[
            AsyncioIntegration(),
            StarletteIntegration(
                transaction_style="endpoint",
                failed_request_status_codes=[403, range(500, 599)],
            ),
            FastApiIntegration(
                transaction_style="endpoint",
                failed_request_status_codes=[403, range(500, 599)],
            ),
        ],
    )
    ui.run(
        title="sheets",
        port=8000,
        storage_secret=os.environ.get("STORAGE_SECRET", "abcdefghijklmnop"),
    )
