import uuid

from nicegui import app, ui
from nicegui.events import ClickEventArguments
from pydantic import BaseModel

from trains.map import Map

maps: dict[str, Map] = {
    "US": Map(),
}


class GameState(BaseModel):
    map_name: str
    players: int

    @property
    def map(self) -> Map:
        return maps[self.map_name]


@ui.page("/")
def initial_page():
    ui.label("New Game 🚂").classes("text-lg font-bold")
    map = ui.select(list(maps.keys()), label="Map")
    players = ui.number(label="Players", value=1)

    button = ui.button("Create Game")

    @button.on_click
    def create_game(event: ClickEventArguments):
        game_id = uuid.uuid4().hex
        app.storage.general[game_id] = GameState(
            map_name=map.value, players=players.value
        ).model_dump()
        ui.navigate.to(f"/game/{game_id}")


@ui.page("/game/{game_id}")
def game_page(game_id: str):
    state = GameState.model_validate(app.storage.general[game_id])


def render_map():
    grid = ui.html()


if __name__ in {"__main__", "__mp_main__"}:
    ui.run()
