import contextlib
from typing import Optional, Type, TypeVar

from nicegui import ui
from nicegui.element import Element

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


row = with_classes(ui.row, "w-full gap-y-0")
col = with_classes(ui.column, "h-full gap-y-0")
growth_col = with_classes(col, "grow")
aligned_baseline_row = with_classes(row, "items-baseline")
aligned_center_row = with_classes(row, "items-center")
long_input = with_classes(ui.input, "w-full gap-y-0")
markdown = with_classes(ui.markdown, "w-full gap-y-0 inline-text")


class radio(ui.radio):
    def __init__(self):
        super().__init__({})
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
