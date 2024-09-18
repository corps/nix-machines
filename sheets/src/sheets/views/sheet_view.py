import contextlib
import dataclasses
import json
import os.path
import uuid
from collections import defaultdict
from contextvars import ContextVar
from functools import cached_property
from typing import Iterator, TypeVar

import pytest
import sentry_sdk
from nicegui import Client, app, ui
from nicegui.element import Element
from nicegui.elements.mixins.value_element import ValueElement
from pydantic import BaseModel, Field, ValidationError

from sheets.async_helpers import capture_events, run_async_renderer
from sheets.components import (
    aligned_baseline_row,
    col,
    long_input,
    markdown,
    radio,
    row,
    with_classes,
)
from sheets.ddb import DEXTERITY, DDBCharacter, load_character
from sheets.storage import ModelStorage

COLUMN_SIZE = 94

_E = TypeVar("_E", bound=Element)
_V = TypeVar("_V", bound=ValueElement)
_T = TypeVar("_T", bound=tuple)


class CharacterSheet(BaseModel):
    last_form: dict[str, str] = Field(default_factory=dict)
    edits: dict[str, str] = Field(default_factory=dict)

    @cached_property
    def next_form(self) -> dict[str, str]:
        return {}

    def complete_form(self):
        for k in list(self.edits.keys()):
            if k in self.last_form and k not in self.next_form:
                del self.edits[k]
        self.last_form = self.next_form.copy()
        self.next_form.clear()


sheet_storage = ModelStorage("sheet_", CharacterSheet, app.storage.general)
character_storage = ModelStorage("character_", DDBCharacter, app.storage.general)


@dataclasses.dataclass
class _Context:
    sheet: CharacterSheet = dataclasses.field(default_factory=lambda: CharacterSheet())
    key_stack: list[str] = dataclasses.field(default_factory=list)
    id_map: dict[str, int] = dataclasses.field(default_factory=dict)


_context = ContextVar("_context", default=_Context())


async def sheet_page(client: Client, ddb_id: int):
    await client.connected()
    sheet = sheet_storage.load(
        ddb_id, lambda: ui.notify("Failed to load saved sheet, resetting state.")
    )
    if sheet is None:
        sheet = CharacterSheet()

    try:
        character = await load_character(ddb_id)
        character_storage.store(ddb_id, character)
    except Exception as e:
        sentry_sdk.capture_exception(e)
        character = character_storage.load(
            ddb_id, lambda: ui.notify("Cannot find character information.")
        )

    if character is None:
        return

    ui.add_css(
        """
@page
{
    size: auto;
    margin: 0mm;
}"""
    )
    sheet_view(sheet, character)
    sheet_storage.store(ddb_id, sheet)
    # run_async_renderer(client, sheet_view(sheet))


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


def apply_heading(element: _E, heading: str) -> _E:
    element.props["form_k"] = heading
    return element


@contextlib.contextmanager
def stat_section(heading: str):
    ctx = _context.get()
    with apply_heading(ui.element().classes(f"gap-y-0 border px-3"), heading) as top:
        key = determine_key(top)
        parents = key.count("/")
        ctx.id_map[key] = top.id

        with ui.element():
            if parents == 0:
                markdown(f"#### {heading}")
            if parents == 1:
                markdown(f"##### {heading}")
            if parents > 1:
                markdown(f"###### {heading}")
        with ui.element().classes("items-baseline"):
            yield top


def number_input(label: str, value: str | int | None) -> int | None:
    with apply_heading(col().classes("w-10"), label):
        i = set_edits(
            long_input(label, value=str(value) if value is not None else "")
        ).value
        try:
            return int(i)
        except ValueError:
            if isinstance(value, int):
                return value
            return None


def name_input(label: str, value: str) -> str:
    with apply_heading(col().classes("w-24"), label):
        return set_edits(long_input(label, value=value))


def set_edits(element: _V) -> _V:
    ctx = _context.get()
    sheet = ctx.sheet
    key = determine_key(element)
    if key in sheet.edits and element.value != sheet.last_form.get(key, None):
        del sheet.edits[key]
    sheet.next_form[key] = element.value
    element.value = sheet.edits.get(key, element.value)
    return element


def sheet_view(sheet: CharacterSheet, character: DDBCharacter):
    _context.set(_Context(sheet=sheet))
    with stat_section("Combat Overview"):
        combat_overview(character)
    sheet.complete_form()
    # await combat_actions(calculator, sheet)
    # await weapon_attacks(calculator, sheet)
    pass


# async def weapon_attacks(calculator: DDBCharacterCalculator, sheet: CharacterSheet):
#     ui.markdown("# Weapon Attacks").style("break-before: page")
#     with row().classes("pl-8"):
#         with stat_section("Primary Hand", 80):
#             with radio() as r:
#                 for weapon in calculator.weapons:
#                     with r.add_radio_item(weapon.id):
#                         with ui.grid(columns=3).classes("w-72 items-baseline"):
#                             with ui.column():
#                                 ui.markdown(
#                                     f"{weapon.definition.name} " + ""
#                                     if not weapon.definition.canAttune
#                                     else (
#                                         "*Attuned*"
#                                         if weapon.isAttuned
#                                         else "*Not Attuned*"
#                                     )
#                                 )
#                             ui.label(weapon.definition.damage.diceString)
#                             ui.label(weapon.definition.damageType)


# async def combat_actions(calculator: DDBCharacterCalculator, sheet: CharacterSheet):
#     ui.markdown("# Standard Combat Actions").style("break-before: page")
#
#     with row().classes("pl-8"):
#         with stat_section("Movement", 80):
#             speeds = " ".join(f"**{name}** {v} ft" for name, v in calculator.speeds)
#             ui.markdown(
#                 f"""
#             {speeds}
#
#             On your turn, you can move a distance up to your speed.  You may change your movement type as you do so, so
#             long as your distance has not exceeded that movement's speed.  You may travel through the spaces of
#             allies, Incapacitated creatures, or those two sizes greater or smaller than you.
#             You can break up your movement on your turn, using some of your speed before and after your action.
#
#             If you take the **Dash** action, you double your walk speed the current turn, including modifiers that reduce or increase it.
#             If you have other speeds, you may double one of those as well, but you must specify which.
#
#             If you take the **Disengage** action, your movement doesn't provoke Opportunity Attacks for the rest of the current turn.
#             """
#             )
#
#         with stat_section("Attack / Magic", 80):
#             ui.markdown(
#                 f"""
#             When you take the **Magic** action, you cast a spell that has a casting time of an action
#             or use a feature or magic item that requires a Magic action to be activated.  You can expend only one
#             spell slot to cast a spell on your turn, and you may only maintain one Concentration spell at a time.
#
#             While concentrating, you are at disadvantage to Wisdom ability rolls, and when you take damage, you must
#             succeed a Constitution saving throw or lose concentration.  The DC is half the damage or 10, whichever
#             is higher.
#
#             When you take the **Attack** action, you make an attack roll with either a weapon or an unarmed free hand.
#             As part of the Attack action, you may *either* equip or unequip *one* weapon, either by
#             sheathing / unsheathing, or picking up / dropping.
#             """
#             )
#
#         with stat_section("Dodge / Escape / Prone", 80):
#             ui.markdown(
#                 f"""
#             If you take the **Dodge** action, you gain the following benefits: until the start of your next turn, any attack roll made against you has Disadvantage if you can see the attacker, and you make Dexterity saving throws with Advantage.
#             You lose these benefits if you have the Incapacitated condition or if your Speed is 0.
#
#             If you take the **Escape** action, you my attempt a Strength or Dexterity saving throw against the grapple
#             DC of one creature you is currently grappling you.  On success, that creature is no longer grappling you.
#             As long as one creature remains grappling you, you have the Grappled condition.
#
#             On your turn, you may give yourself the **Prone** condition as long as your speed is not 0.  You may remove
#             your Prone condition by spending 15ft of movement.
#             """
#             )
#
#         with stat_section("Hide / Search / Utilize", 80):
#             ui.markdown(
#                 f"""
#             If you take the **Hide** action, you make a Stealth roll ({calculator.calculate_skill_mod("stealth"):+})
#             against a DC of 15. If you succeed and are either out of line of sight or heavily obscured for all enemies,
#             you have the Invisible condition.
#
#             The condition ends on you immediately after any of the following occurs: you make a sound louder than a
#             whisper, an enemy finds you, you make an attack roll, or you cast a spell with a Verbal component.
#
#             If you take the **Search** action, you make a Perception roll.  If your roll meets or exceeds
#             the Stealth rolls of any nearby enemies you could hear or see, their Invisible condition ends.
#
#             If you take the **Utilize** action, you may invoke the Utilize action associated with an item or
#             an object within your reach.  Check item descriptions or ask the GM for how these actions might work.
#             """
#             )
#
#         with stat_section("Help / Influence", 80):
#             ui.markdown(
#                 f"""
#             If you take the **Help** action, you give Advantage to the next attack roll by one of your allies
#             against an enemy within 5 feet of you. This benefit expires at the start of your next turn.
#
#             If you take the **Influence** action, you describe how your character makes a request of a target
#             creature that can see or hear you.  If the target is unwilling, the action fails.  If the target is
#             hesitant, you make a social skill roll against DC 15 or the target's intelligence score, whichever
#             is higher.  On success, the target will attempt to comply with the request on its next action.
#
#             If the target can hear and understand you, you may use Persuasion ({calculator.calculate_skill_mod("persuasion"):+})
#             or Deception ({calculator.calculate_skill_mod("deception"):+}).
#             If the target can hear you but not understand you, you may use Performance ({calculator.calculate_skill_mod("performance"):+})
#             or Animal Handling ({calculator.calculate_skill_mod("animal handling"):+}).
#             If the target can see you, you may use Intimidation ({calculator.calculate_skill_mod("intimidation"):+}).
#             """
#             )
#
#         with stat_section("Grapple / Shove", 80):
#             ui.markdown(
#                 f"""
#             If you make an **unarmed attack** with a free hand, you may substitute that attack roll with either
#             a grapple or a shove.  In either case, the target must roll a Strength or Dexterity saving throw against
#             DC {calculator.grapple_dc}.
#
#             For a **grapple**, a failure results in the target receiving the Grappled condition for as long as they remain
#             within your reach, and your unarmed attack hand remains free.  A Grappled target has their speed set to
#             zero, and they are disadvantage to attack any target that is not currently grappling them.
#
#             For a **shove**, a failure results in the target either being knocked prone or pushed 5 feet away from you.
#             """
#             )


def combat_overview(character: DDBCharacter):
    with stat_section("HP"), ui.row():
        number_input("Cur", value=character.cur_hp)
        number_input("Temp", value=character.temp_hp)
        number_input("Max", value=character.max_hp)

    markdown(
        character.apply_template_variables(
            f"""
    <ins>**Opportunity Attack**</ins>
   When a creature that you can see leaves your reach on its turn or when using an action, a reaction, or its own movement, you may take a Reaction to make one melee attack against the provoking creature. The attack occurs right before the creature leaves your reach.
    """
        )
    )

    with stat_section("AC"):
        markdown("*Don't forget to apply shield bonus when holding one*")
        with radio() as r:
            for armor in character.armors:
                with r.add_radio_item(armor.id), apply_heading(row(), f"{armor.id}"):
                    name_input("Name", armor.definition.name)
                    base = number_input("Base", armor.definition.armorClass)
                    mod = character.calculate_mod(DEXTERITY)
                    if armor.max_dex_modifier is not None:
                        mod = min(armor.max_dex_modifier, mod)
                    mod = number_input("Mod", mod)
                    number_input("Total", base + mod)

            with r.add_radio_item(), apply_heading(row(), "Unarmored"):
                name_input("Name", "Unarmored")
                base = number_input("Base", 10)
                mod = character.calculate_mod(DEXTERITY)
                for modifier in character.all_modifiers:
                    if (
                        modifier.subType == "unarmored-armor-class"
                        and modifier.statId is not None
                    ):
                        mod += character.calculate_mod(modifier.statId - 1)

                mod = number_input("Mod", mod)
                number_input("Total", base + mod)

            records = find_custom_records(r, "custom")
            for heading, record in records:
                with r.add_radio_item(), apply_heading(row(), heading):
                    name_input("Name", record["Name"])
                    base = number_input("Base", record["Base"]) or 10
                    mod = character.calculate_mod(DEXTERITY)
                    mod = number_input("Mod", mod)
                    number_input("Total", base + mod)

            with r.add_radio_item() as c, apply_heading(row(), f"custom/{c}"):
                name_input("Name", "")
                base = number_input("Base", 10)
                mod = character.calculate_mod(DEXTERITY)
                mod = number_input("Mod", mod)
                number_input("Total", base + mod)


#     armors = [armor_label(armor, calculator) for armor in calculator.armors] + [
#         armor_label(None, calculator)
#     ]
#     with row().classes("pl-8"):
#         with stat_section("AC", 48):
#             ui.select(armors, value=armor_label(sheet.current_armor, calculator))
#         with stat_section("Initiative", 32):
#             with short_col():
#                 long_input(value=f"{calculator.initiative}").disable()
#         with stat_section("Saves", 40):
#             with ui.grid(rows=2, columns=3).classes("gap-y-0 leading-none"):
#                 for idx, label in stat_name.items():
#                     ui.markdown(
#                         f"**{label.capitalize()[:3]}** {calculator.calculate_saving_throw(idx)}"
#                     )
#
#         if calculator.immunities:
#             with stat_section("Immunities", 32):
#                 ui.label(", ".join(calculator.immunities))
#         if calculator.resistances:
#             with stat_section("Resistances", 32):
#                 ui.label(", ".join(calculator.resistances))
#         with stat_section("Reactions", "full"):
#             with col().classes("w-80"):
#                 ui.markdown(
#                     calculator.apply_template_variables(
#                         f"""
#                     <ins>**Opportunity Attack**</ins>
#
#                     When a creature that you can see leaves your reach on its turn or when using an action, a reaction, or its own movement, you may take a Reaction to make one melee attack against the provoking creature. The attack occurs right before the creature leaves your reach.
#                 """
#                     )
#                 )
#             for action_or_spell, class_spells in calculator.reactions:
#                 with col().classes("w-80"):
#                     if isinstance(action_or_spell, Action):
#                         ui.markdown(
#                             calculator.apply_template_variables(
#                                 f"""
#                             <ins>**{action_or_spell.name}**</ins>
#
#                             {action_or_spell.snippet or action_or_spell.description or ''}
#                         """
#                             )
#                         )
#                     elif isinstance(action_or_spell, Spell):
#                         ui.markdown(
#                             calculator.apply_template_variables(
#                                 f"""
#                             <ins>**{action_or_spell.definition.name}**</ins>
#
#                             {action_or_spell.definition.snippet or action_or_spell.definition.description or ''}
#                         """
#                             )
#                         )


@pytest.mark.asyncio
async def test_get_characters():
    for ddb_id in (45344354, 112315775):
        character = await load_character(ddb_id)
        DDBCharacter.model_validate(character.model_dump(mode="json", by_alias=True))

        client = Client(ui.page("/"), request=None)
        character_sheet = CharacterSheet()
        with ui.element("div", _client=client):
            sheet_view(character_sheet, character)

        path = f"sheet.{ddb_id}.json"
        if os.path.exists(path):
            with open(path, "r") as f:
                zz = json.loads(f.read())
                for k, v in character_sheet.last_form.items():
                    if k in zz:
                        assert (
                            character_sheet.last_form[k] == v
                        ), f"Did not match for {k}"
                for k, v in zz.items():
                    if k not in character_sheet.last_form:
                        raise AssertionError(f"New sheet missing {k}")
        with open(path, "w") as f:
            f.write(json.dumps(character_sheet.last_form, indent=2))
