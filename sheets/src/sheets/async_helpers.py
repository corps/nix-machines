import asyncio
import dataclasses
from contextlib import AbstractAsyncContextManager
from typing import (
    Any,
    AsyncContextManager,
    Awaitable,
    ContextManager,
    Generic,
    Iterable,
    TypeVar,
)

from nicegui import Client, context, ui
from nicegui.elements.mixins.disableable_element import DisableableElement
from nicegui.elements.mixins.validation_element import ValidationElement
from nicegui.elements.mixins.value_element import ValueElement
from nicegui.events import UiEventArguments
from nicegui.functions.refreshable import RefreshableContainer

_T = TypeVar("_T")


def run_async_renderer(client: Client, renderer: Awaitable):
    container = RefreshableContainer()

    async def run_renderer(r: Awaitable):
        with container:
            while True:
                result = await r
                if asyncio.iscoroutine(result):
                    container.clear()
                    r = result
                else:
                    break

    t = asyncio.create_task(run_renderer(renderer))
    t.add_done_callback(lambda t_: client.disconnect_handlers.remove(t_.cancel))
    client.on_disconnect(t.cancel)


@dataclasses.dataclass
class capture_events:
    events: Iterable[str] = ()
    parent: "capture_events | None" = None
    payload: Any = None
    queue: asyncio.Queue = dataclasses.field(default_factory=lambda: asyncio.Queue())
    _busy: list[DisableableElement] = dataclasses.field(default_factory=list)
    _validate: list[ValidationElement] = dataclasses.field(default_factory=list)

    def capture(
        self, events: Iterable[str] = (), payload: Any = None
    ) -> "capture_events":
        return capture_events(events, self, payload)

    def get(self) -> "Awaitable[tuple[UiEventArguments, tuple[capture_events, ...]]]":
        return self.queue.get()

    def busy(self) -> "busy":
        return busy(self._busy)

    def validate(self, event: UiEventArguments) -> "validate":
        return validate(self._validate, event)

    def __post_init__(self):
        def publish(e: UiEventArguments):
            events = self
            sources = (events,)
            while events is not None:
                events.queue.put_nowait((e, sources))
                events = events.parent
                sources = (*sources, events)

        slot_stack = context.slot_stack
        if slot_stack:
            slot = slot_stack[-1]
            for event in self.events:
                print(event)
                slot.parent.on(event, publish)
            events = self
            while events is not None:
                if isinstance(slot.parent, DisableableElement):
                    events._busy.append(slot.parent)
                if isinstance(slot.parent, ValidationElement):
                    events._validate.append(slot.parent)
                events = events.parent


@dataclasses.dataclass
class busy(ContextManager[tuple[DisableableElement, ...]]):
    elements: Iterable[DisableableElement]

    def __enter__(self):
        for e in self.elements:
            e.disable()
        return self.elements

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            ui.notify("Unexpected Error")

        for e in self.elements:
            e.enable()


@dataclasses.dataclass
class validate(ContextManager[tuple[ValidationElement, ...]]):
    elements: Iterable[ValidationElement]
    event: UiEventArguments

    def __enter__(self):
        return self.elements

    def __exit__(self, exc_type, exc_val, exc_tb):
        for e in self.elements:
            if e is self.event.sender:
                if exc_type is AssertionError:
                    if isinstance(exc_val, AssertionError):
                        if exc_val.args:
                            e.validation = {}
                            e.error = exc_val.args[0]
                            return True
                    e.error = "Invalid"
                    return True
                e.error = None
                break