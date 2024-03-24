from nicegui import ui

with ui.column().classes("w-full max-w-3xl mx-auto my-6"):
    with ui.row().classes("w-full no-wrap items-center"):
        ui.label("Search: ")
        search = (
            ui.input(placeholder="message")
            .props("rounded outlined input-class=mx-3")
            .classes("flex-grow")
        )
    # ui.markdown("simple chat app built with [NiceGUI](https://nicegui.io)").classes(
    #     "text-xs self-end mr-8 m-[-1em] text-primary"
    # )


if __name__ in {"__main__", "__mp_main__"}:
    ui.run(title="libbiz", port=8080)
