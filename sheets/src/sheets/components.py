import contextlib
import re
from typing import Callable, Optional, Type, TypeVar

from nicegui import ui
from nicegui.element import Element
from nicegui.events import GenericEventArguments, UiEventArguments

_E = TypeVar("_E", bound=Element)


def with_classes(
    c: Type[_E],
    add: Optional[str] = None,
    *,
    remove: Optional[str] = None,
    replace: Optional[str] = None,
) -> Type[_E]:
    def __init__(self, *args, **kwds):
        super(t, self).__init__(*args, **kwds)
        self.classes(add=add, remove=remove, replace=replace)

    t = type(c.__name__, (c,), {"__init__": __init__})
    return t


row = with_classes(ui.row, "w-full items-baseline")
col = with_classes(ui.column, "h-full")
growth_col = with_classes(col, "grow")
aligned_baseline_row = with_classes(row, "items-baseline")
aligned_center_row = with_classes(row, "items-center")
full_input = with_classes(ui.input, "w-full")
markdown = with_classes(ui.markdown, "")


def _escape_md(text: str) -> str:
    escape_chars = r"_*[]()~`<>#+-=|{}.!"
    return re.sub(f"([{re.escape(escape_chars)}])", r"\\\1", text)


class editable_markdown(ui.markdown):
    template: str
    transformer: Callable[[str], str]

    def __init__(self, template: str, transformer: Callable[[str], str] | None = None):
        self.transformer = transformer
        self.template = template
        super().__init__(transformer(template) if transformer else template)
        self.props("contenteditable")

        def _on_click(*e):
            self.content = _escape_md(self.template)

        def _on_blur(*e):
            self.content = transformer(self.template) if transformer else self.template

        async def _on_change(e: GenericEventArguments):
            self.template = await ui.run_javascript(
                f"document.getElementById('c' + {repr(e.sender.id)}).innerText"
            )

        self.on("click", _on_click)
        self.on("blur", _on_blur)
        self.on("input", _on_change)


@contextlib.contextmanager
def left_group():
    with ui.element().classes("clearfix"):
        with ui.element().classes("float-left"):
            yield


class radio(ui.radio):
    def __init__(self, value: int | None = None):
        super().__init__({}, value=value)
        self.classes("w-full")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass

    @contextlib.contextmanager
    def add_radio_item(self, key: int | None = None, selected=False):
        if key is None:
            key = max(self.options.keys(), default=0) + 1
        self.set_options(
            {**self.options, key: ""}, value=key if selected else self.value
        )
        with ui.teleport(
            f"#c{self.id} div:nth-child({len(self.options)})  .q-radio__label"
        ) as t:
            yield key
            for e in t.default_slot.children:
                for event_name in ("click", "keydown", "keypress", "keyup"):
                    e.on(event_name, js_handler="(e) => { e.stopPropagation() }")
