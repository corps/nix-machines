import asyncio
from asyncio import Task
from typing import Any, Awaitable, Callable, ParamSpec, TypeVar

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
