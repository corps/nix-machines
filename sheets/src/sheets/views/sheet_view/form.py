import contextlib
import dataclasses
import re
from collections import defaultdict
from contextvars import ContextVar
from enum import IntEnum
from typing import Iterable, TypeVar

from nicegui import ui
from nicegui.element import Element
from nicegui.elements.mixins.value_element import ValueElement

from sheets.components import col, editable_markdown, full_input, markdown, radio, row
from sheets.ddb import (
    Action,
    Armor,
    ClassSpells,
    DDBCharacter,
    Item,
    LimitedUse,
    Shield,
    Spell,
    Weapon,
)
from sheets.views.sheet_view.sheet import CharacterSheet

_E = TypeVar("_E", bound=Element)
_V = TypeVar("_V", bound=ValueElement)


class Widths(IntEnum):
    ONE0 = 10
    ONE6 = 16
    THREE6 = 36
    FOUR8 = 48
    SIX4 = 64
    SEVEN2 = 72
    EIGHT0 = 80


def determine_key(e: Element | None) -> str:
    result = []
    while e is not None:
        if "form_k" in e.props:
            result.insert(0, e.props["form_k"])
        if e.parent_slot is None:
            break
        e = e.parent_slot.parent
    return "/".join(result)


def find_custom_records(
    e: Element | None, suffix: str
) -> list[tuple[str, dict[str, str]]]:
    key = determine_key(e) + "/" + suffix
    ctx = _context.get()
    results: dict[str, dict[str, str]] = defaultdict(dict)
    for k, v in ctx.sheet.edits.items():
        if k.startswith(key):
            identifier, _, subkey = k[len(key) :].partition("/")
            results[identifier][subkey] = v
    return list(results.items())


@dataclasses.dataclass
class _Context:
    sheet: CharacterSheet = dataclasses.field(default_factory=lambda: CharacterSheet())
    key_stack: list[str] = dataclasses.field(default_factory=list)
    id_map: dict[str, int] = dataclasses.field(default_factory=dict)


_context = ContextVar("_context", default=_Context())


def apply_heading(element: _E, heading: str) -> _E:
    element.props["form_k"] = heading
    return element


@contextlib.contextmanager
def stat_section(heading: str | Element, horizontal: bool = False, items="baseline"):
    ctx = _context.get()
    with (
        ui.element().classes("w-full")
        if not horizontal
        else ui.row().classes(f"items-{items} w-full")
    ) as top:
        if isinstance(heading, str):
            apply_heading(top, heading)
        key = determine_key(top)
        parents = key.count("/")
        ctx.id_map[key] = top.id

        with contextlib.ExitStack() as stack:
            if not horizontal:
                parent = stack.enter_context(row())
            else:
                parent = stack.enter_context(col())
            if isinstance(heading, Element):
                heading.move(parent)
            else:
                if parents == 0:
                    markdown(f"#### {heading}")
                if parents == 1:
                    markdown(f"##### {heading}")
                if parents > 1:
                    markdown(f" **{heading}**")
        with contextlib.ExitStack() as stack:
            if not horizontal:
                stack.enter_context(row().classes(f"items-{items} justify-around"))
            else:
                stack.enter_context(col())
            yield top


def short_input(label: str, value: str | int | None):
    with apply_heading(col().classes("w-10"), label):
        set_edits(full_input(label, value=str(value) if value is not None else ""))


class limited_use_input(ValueElement):
    def __init__(self, character: DDBCharacter, limited_use: LimitedUse):
        self.character = character
        self.heading = str
        self.limited_use = limited_use
        self.checkboxes: list[ui.checkbox] = []
        self.value = limited_use.numberUsed

        def apply_checks(*_):
            for i, checkbox in enumerate(self.checkboxes):
                checkbox.value = i < self.value

        super().__init__(value=limited_use.numberUsed, on_value_change=apply_checks)
        self.classes("w-full")

        def add_checkbox(i: int):
            async def on_change(*_):
                if self.value > i:
                    self.value = i
                else:
                    self.value = i + 1

            self.checkboxes.append(
                ui.checkbox(
                    (
                        f"{limited_use.resetType or ''}"
                        if i == limited_use.max_uses(character) - 1
                        else ""
                    ),
                    value=i < limited_use.numberUsed,
                ).on("click", on_change)
            )

        with self:
            for i in range(self.limited_use.max_uses(character)):
                add_checkbox(i)


def dice_input(label: str, value: str | int | None):
    with apply_heading(col().classes("w-16"), label):
        set_edits(full_input(label, value=str(value) if value is not None else ""))


def name_input(label: str, value: str) -> str:
    with apply_heading(col().classes("w-36"), label):
        return set_edits(full_input(label, value=value))


def set_edits(element: _E) -> _E:
    ctx = _context.get()
    sheet = ctx.sheet
    key = determine_key(element)
    if isinstance(element, radio):
        if key in sheet.edits and element.value != sheet.last_form.get(key, None):
            del sheet.edits[key]
        sheet.next_form[key] = str(element.value) if element.value is not None else ""
        edit_value = sheet.edits.get(key, sheet.next_form[key])
        element.value = int(edit_value) if edit_value else None
    elif isinstance(element, ValueElement):
        if key in sheet.edits and element.value != sheet.last_form.get(key, None):
            del sheet.edits[key]
        sheet.next_form[key] = element.value
        element.value = sheet.edits.get(key, element.value)
    elif isinstance(element, editable_markdown):
        if key in sheet.edits and element.template != sheet.last_form.get(key, None):
            del sheet.edits[key]
        sheet.next_form[key] = element.template
        element.template = sheet.edits.get(key, element.template)
    else:
        raise ValueError(f"Element not valid for set_edits")

    return element


@contextlib.contextmanager
def blocked_overview(character: DDBCharacter, width: int | str = 72):
    descriptions: list[tuple[str, str]] = []
    starting_actions = character.taken_actions.copy()
    starting_spells = character.taken_spells.copy()
    starting_items = character.taken_items.copy()
    with ui.element().classes("clearfix w-full"):
        with ui.element().classes(f"float-right w-{width} mx-4 mb-4"):
            yield descriptions

            for desc in describe_items(character, starting_items):
                descriptions.append(desc)

            accessed_descriptive_modifiers(character)
            describe_limited_uses(character, starting_actions, starting_spells)
            describe_spells(character, starting_spells)

        for heading, description in descriptions:
            ui.link_target(heading)
            markdown(re.sub(r"<[^<]+?>", "", re.sub(r"\[[^]]*\]", "", description)))


def accessed_descriptive_modifiers(character: DDBCharacter):
    for subtype in character.drain_applied_modifiers():
        for leveraged in character.get_leveraged_modifiers(subtype):
            markdown(
                f"**{subtype} {leveraged.type}**: {leveraged.restriction or 'always'}"
            )
        for applied in character.get_conditional_applied_modifiers(subtype):
            markdown(
                f"**{subtype} - {applied.friendlyTypeName.lower()} {character.get_applied_modifier_value(applied)}**: {applied.restriction}"
            )


def spell_heading(spell: Spell):
    return f"Spell/{spell.definition.id}"


def action_heading(action: Action):
    return f"Action/{action.id}"


def spell_link(spell: Spell):
    heading = spell_heading(spell)
    return apply_heading(ui.link(spell.definition.name, f"#{heading}"), heading)


def action_link(action: Action):
    heading = action_heading(action)
    return apply_heading(ui.link(action.name, f"#{heading}"), heading)


def describe_limited_uses(
    character: DDBCharacter,
    starting_actions: set[Action],
    starting_spells: set[tuple[Spell, ClassSpells | None]],
):
    new_actions = character.taken_actions - starting_actions
    new_spells = character.taken_spells - starting_spells
    limited_use_spells = [spell for spell, _ in new_spells if spell.limitedUse]
    limited_use_actions = [action for action in new_actions if action.limitedUse]
    if not limited_use_spells and not limited_use_actions:
        return

    with stat_section("Limited Uses"):
        for action in limited_use_actions:
            with stat_section(action_link(action), items="center"), row():
                limited_use_input(character, action.limitedUse)
        for spell in limited_use_spells:
            with stat_section(spell_link(spell), items="center"), row():
                limited_use_input(character, spell.limitedUse)


def describe_items(
    character: DDBCharacter, starting_items: set[Item]
) -> Iterable[tuple[str, str]]:
    new_items = character.taken_items - starting_items
    for item in new_items:
        d = item.definition
        if isinstance(d, Armor.ArmorDefinition):
            yield f"Armors/{d.id}", f"""
**{d.name}** {d.armorTypeId} Armor *{d.weight} lbs*

{d.description}
            """
        elif isinstance(d, Weapon.WeaponDefinition):
            props = "\n\n".join(
                f"{p.name}: {re.sub('<[^<]+?>', '', p.description)}"
                for p in d.properties
            )
            r = "" if d.longRange == 5 else f"({d.range} / {d.longRange} ft)"

            yield f"Weapons/{d.id}", f"""
**{d.name}** {d.damage} {d.damageType} {r} *{d.weight} lbs*

{d.description if d.name != d.type else ""}
{props}
"""
        elif isinstance(d, Shield.ShieldDefinition):
            if d.type == d.name:
                continue
            yield f"Shields/{d.id}", f"""
**{d.name}** *{d.weight} lbs*

{d.description}
"""


def describe_spells(
    character: DDBCharacter, starting_spells: set[tuple[Spell, ClassSpells]]
):
    new_spells = character.taken_spells - starting_spells
    concentration_spells = [
        (spell, class_spells)
        for spell, class_spells in new_spells
        if spell.definition.duration.durationType == "Concentration"
    ]
    duration_spells = [
        (spell, class_spells)
        for spell, class_spells in new_spells
        if spell.definition.duration.durationType == "Time"
    ]
    instant_spells = [
        (spell, class_spells)
        for spell, class_spells in new_spells
        if spell.definition.duration.durationType == "Instantaneous"
    ]
    ranged_spells = [
        (spell, class_spells)
        for spell, class_spells in new_spells
        if spell.range.origin == "Ranged"
    ]
    self_spells = [
        (spell, class_spells)
        for spell, class_spells in new_spells
        if spell.range.origin == "Self"
    ]

    if concentration_spells:
        with stat_section("Concentration"):
            for spell, class_spells in concentration_spells:
                with set_edits(radio()) as r:
                    with r.add_radio_item(spell.definition.id):
                        spell_link(spell)

    if duration_spells:
        with stat_section("Persistent"):
            for spell, class_spells in duration_spells:
                with col().classes("grow"):
                    spell_link(spell)
                with col().classes("grow"):
                    ui.label(str(spell.definition.duration))

    if instant_spells:
        with stat_section("Instant"):
            for spell, class_spells in instant_spells:
                with col().classes("grow"):
                    spell_link(spell)
                with col().classes("grow"):
                    ui.label(str(spell.definition.duration))

    if ranged_spells:
        with stat_section("Ranged"):
            for spell, class_spells in ranged_spells:
                with col().classes("grow"):
                    spell_link(spell)
                with col().classes("grow"):
                    ui.label(str(spell.range))
