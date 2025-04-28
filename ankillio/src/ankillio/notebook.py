import os
from typing import Awaitable, Protocol

from dotenv import find_dotenv, load_dotenv
from mistralai import Mistral
from nicegui import Client, app, ui
from nicegui.events import GenericEventArguments
from pydantic import BaseModel, Field

from ankillio.anki import AnkiService, Embedded, query_similar, sync
from ankillio.async_helpers import capture_events, context, run_async_renderer
from ankillio.storage import ModelStorage, PerFileStorage

load_dotenv(find_dotenv())


class Row(BaseModel):
    tool: str = "chat"
    subtool: str = ""
    name: str = ""
    prompt: str = ""
    subprompt: str = ""
    responses: list[str] = Field(default_factory=list)

    @property
    def tool_tuple(self):
        return self.tool, self.subtool

    @tool_tuple.setter
    def tool_tuple(self, v):
        self.tool, self.subtool = v


class Notebook(BaseModel):
    rows: list[Row] = Field(default_factory=list)


class Notebooks(BaseModel):
    tabs: dict[str, Notebook] = Field(default_factory=lambda: dict(default=Notebook()))


class Tool(Protocol):
    def __call__(self, notebook: Notebook, row: Row) -> Awaitable[list[str]]: ...


tools: dict[str, Tool] = {}


def register_tool(c: Tool) -> Tool:
    tools[c.__name__] = c
    return c


@register_tool
async def chat(notebook: Notebook, row: Row) -> list[str]:
    client = Mistral(api_key=os.environ["MISTRAL_API_KEY"])
    messages = [{"content": row.prompt, "role": "user"}]
    if row.subprompt:
        messages.insert(0, {"content": row.subprompt, "role": "user"})
    response = await client.chat.complete_async(
        model="mistral-small-latest",
        messages=messages,
    )
    return [c.message.content for c in response.choices]


@register_tool
async def prompt(notebook: Notebook, row: Row) -> list[str]:
    count = 0
    for r in notebook.rows:
        if r.tool == "chat" and r.subtool == row.name:
            if r.subprompt != row.prompt:
                r.subprompt = row.prompt
                count += 1
    return [f"Updated {count} rows"]


@register_tool
async def anki(notebook: Notebook, row: Row) -> list[str]:
    cards = await do_anki_sync()
    similar = await query_similar(
        row.prompt, Mistral(api_key=os.environ["MISTRAL_API_KEY"]), cards
    )
    return [
        f"<br/>{e.card.answer}<br/><a href='/anki-open/{e.card.note}' target='_blank'>open in anki</a>"
        for e in similar
    ]


version = "v1"


async def do_anki_sync() -> list[Embedded]:
    ui.notify("Starting anki sync...")
    result = await sync(
        ModelStorage("cards_", Embedded, PerFileStorage()),
        Mistral(api_key=os.environ["MISTRAL_API_KEY"]),
    )
    return result


async def main(client: Client):
    storage = ModelStorage("state_", Notebooks, app.storage.user)
    notebooks: Notebooks = storage.load(version, lambda: Notebooks())

    events = capture_events()
    change_events = events.capture()
    change_tool_events = change_events.capture()
    submit_row_events = change_events.capture()
    remove_row_events = change_events.capture()
    move_row_up_events = change_events.capture()
    move_row_down_events = change_events.capture()
    as_row_event = change_events.capture()
    add_tab_event = change_events.capture()
    remove_tab_event = change_events.capture()

    notebook_context = context(Notebook)
    row_context = context(Row)
    response_context = context(str)

    def make_row(notebook: Notebook, row: Row):
        prompts = [row.name for row in notebook.rows if row.tool == "prompt"]
        base_tools = {(k, ""): k for k in tools.keys()}
        prompt_tools = {("chat", prompt): f"chat: {prompt}" for prompt in prompts}
        all_tools = {**base_tools, **prompt_tools}
        with ui.row().classes("w-full"):
            row_context(row)
            if row in notebook.rows:
                with ui.button("X").classes("mt-3 px-2"):
                    remove_row_events.capture(["click"])
                if notebook.rows.index(row) > 0:
                    with ui.button("ꜛ").classes("mt-3 px-2"):
                        move_row_up_events.capture(["click"])
                if notebook.rows.index(row) < len(notebook.rows) - 1:
                    with ui.button("ꜜ").classes("mt-3 px-2"):
                        move_row_down_events.capture(["click"])

            with ui.input(label="Name") as name:
                name.bind_value(row, "name")
                change_events.capture(["blur"])
            with ui.select(all_tools) as select_tool:
                select_tool.bind_value(row, "tool_tuple")
                change_tool_events.capture(["change"])

            with ui.row().classes("w-full"), ui.editor(value=row.prompt).classes(
                "w-full"
            ) as textarea:
                textarea.props["rows"] = 2
                textarea.bind_value(row, "prompt")
                change_events.capture(["blur"])
                submit_row_events.capture(["keypress"])

            if row in notebook.rows:
                for response in row.responses:
                    response_context(response)
                    with ui.row():
                        with ui.context_menu():
                            with ui.menu_item("As row"):
                                as_row_event.capture(["click"])
                        ui.markdown(response)

    with ui.element().style(
        "width: 100%; max-width: 700px; margin-left: auto; margin-right: auto; list-style-type: upper-roman"
    ):
        tab_items = {}
        with ui.tabs().classes("w-full") as tabs:
            for tab_name, _ in notebooks.tabs.items():
                tab_items[tab_name] = ui.tab(tab_name)
            with ui.button("+ Tab").classes("mt-1 mx-2"):
                add_tab_event.capture(["click"])
            if len(tab_items) > 1:
                with ui.button("- Tab").classes("mt-1 mx-2"):
                    remove_tab_event.capture(["click"])

        with ui.tab_panels(tabs, value=next(iter(tab_items.values()))):
            for tab_name, notebook in notebooks.tabs.items():
                notebook_context(notebook)
                with ui.tab_panel(tab_items[tab_name]).classes("w-full"):
                    for row in notebook.rows:
                        make_row(notebook, row)
                    make_row(notebook, Row())

    while True:
        event, sources, slot = await events.get()
        notebook = notebook_context.payload_for(slot)
        row = row_context.payload_for(slot)
        response = response_context.payload_for(slot)

        if as_row_event in sources:
            notebook.rows.append(Row(tool="chat", prompt=response))
        if change_tool_events in sources:
            row.subprompt = next(
                (
                    row.prompt
                    for row in notebook.rows
                    if row.tool == "prompt" and row.name == row.subtool
                ),
                "",
            )
        if remove_row_events in sources:
            notebook.rows.remove(row)
        if move_row_up_events in sources:
            i = notebooks.rows.index(row)
            notebook.rows.remove(row)
            notebook.rows.insert(i - 1, row)
        if move_row_down_events in sources:
            i = notebooks.rows.index(row)
            notebook.rows.remove(row)
            notebook.rows.insert(i + 1, row)
        if submit_row_events in sources:
            if (
                isinstance(event, GenericEventArguments)
                and event.args["shiftKey"]
                and event.args["key"] == "Enter"
            ):
                with change_events.busy():
                    row.responses = []
                    if notebook and row and row not in notebook.rows:
                        notebook.rows.append(row)
                    row.responses = await tools[row.tool](notebook, row)
            else:
                continue
        if add_tab_event in sources:
            notebooks.tabs[str(len(notebooks.tabs))] = Notebook()
        if remove_tab_event in sources:
            del notebooks.tabs[str(len(notebooks.tabs) - 1)]
        if change_events in sources:
            storage.store(version, notebooks)
            return main(client)


@ui.page("/")
async def main_page(client: Client):
    await client.connected()
    run_async_renderer(client, main(client))


@ui.page("/anki-open/{noteId}")
async def open_anki(client: Client, noteId: str):
    await AnkiService().gui_edit_note(int(noteId))
    ui.label("Opened in anki")


if __name__ in {"__main__", "__mp_main__"}:
    ui.dark_mode(True)
    ui.run(storage_secret=os.environ.get("STORAGE_SECRET", "secret"))
