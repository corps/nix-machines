import asyncio
import contextlib
from asyncio import Task
from typing import Any, Awaitable, Callable, Coroutine, ParamSpec, TypeVar

from nicegui.elements.button import Button
from nicegui.elements.input import Input
from nicegui.elements.mixins.disableable_element import DisableableElement

_P = ParamSpec("_P")
_R = TypeVar("_R")


def debounce(
    time: int,
) -> Callable[[Callable[_P, Awaitable[_R]]], Callable[_P, Awaitable[_R]]]:
    def debounce(f: Callable[_P, Awaitable[_R]]) -> Callable[_P, Awaitable[_R]]:
        last_task: Task[_R] | None = None

        async def wrapper(*args: Any, **kwargs: Any) -> _R:
            nonlocal last_task

            async def run():
                await asyncio.sleep(time)
                return await f(*args, **kwargs)

            if last_task is not None:
                last_task.cancel()
            last_task = asyncio.create_task(run())
            return await last_task

        return wrapper

    return debounce


_Awaitable = TypeVar("_Awaitable", bound=Awaitable)


@contextlib.asynccontextmanager
async def disabled(*elements: DisableableElement):
    for element in elements:
        element.set_enabled(False)

    try:
        yield
    finally:
        for element in elements:
            element.set_enabled(True)


def submits_with(
    *elements: DisableableElement,
) -> Callable[[Callable[[], _Awaitable]], Callable]:
    def dec(f: Callable[[], _Awaitable]) -> Callable:
        async def wrapper() -> Any:
            async with disabled(*elements):
                result = f()
                await result
                return result

        for element in elements:
            if isinstance(element, Input):
                element.on("keydown.enter", wrapper)
            elif isinstance(element, Button):
                element.on("click", wrapper)

        return wrapper

    return dec


async def concurrently_run(co: list[Coroutine], max_concurrency: int):
    semaphore = asyncio.Semaphore(value=max_concurrency)

    async def run_coro(coro: Coroutine):
        async with semaphore:
            await coro

    async with asyncio.TaskGroup() as tg:
        for coro in co:
            tg.create_task(run_coro(coro))
