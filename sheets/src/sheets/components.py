from typing import Optional, Type, TypeVar

from nicegui import ui
from nicegui.element import Element

_E = TypeVar("_E", bound=Element)


def with_classes(
    c: Type[_E],
    add: Optional[str] = None,
    *,
    remove: Optional[str] = None,
    replace: Optional[str] = None
) -> Type[_E]:
    def __init__(self, *args, **kwds):
        super(t, self).__init__(*args, **kwds)
        self.classes(add=add, remove=remove, replace=replace)

    t = type(c.__name__, (c,), {"__init__": __init__})
    return t


row = with_classes(ui.row, "w-full")
col = with_classes(ui.column, "h-full")
growth_col = with_classes(col, "grow")
aligned_baseline_row = with_classes(row, "items-baseline")
aligned_center_row = with_classes(row, "items-center")
long_input = with_classes(ui.input, "w-full")
