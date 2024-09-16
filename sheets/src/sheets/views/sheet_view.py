import contextlib
import json

from nicegui import Client, app, ui
from pydantic import ValidationError

from sheets.async_helpers import run_async_renderer
from sheets.components import (
    aligned_baseline_row,
    aligned_center_row,
    col,
    long_input,
    row,
    with_classes,
)
from sheets.ddb import (
    Action,
    Armor,
    CharacterSheet,
    DDBCharacter,
    DDBCharacterCalculator,
    Spell,
    load_sheet,
    skills,
    stat_name,
    update_sheet,
)


async def store_sheet(sheet: CharacterSheet):
    app.storage.general[f"sheet_{sheet.last_loaded.data.id}"] = sheet.model_dump(
        mode="json", by_alias=True
    )


async def sheet_page(client: Client, ddb_id: int):
    await client.connected()
    sheet_data = app.storage.general.get(f"sheet_{ddb_id}", None)
    sheet = None
    if sheet_data is not None:
        try:
            sheet = CharacterSheet.model_validate(sheet_data)
        except ValidationError:
            ui.notify("Failed to load saved character")

    if sheet is None:
        sheet = await load_sheet(ddb_id)

    if sheet is None:
        return

    await update_sheet(sheet)
    await store_sheet(sheet)

    run_async_renderer(client, sheet_view(sheet))


def armor_label(armor: Armor | None, calculate: DDBCharacterCalculator) -> str:
    if not armor:
        return f"No Armor ({calculate.effective_ac(armor)})"
    return f"{armor.definition.name} ({calculate.effective_ac(armor)})"


@contextlib.contextmanager
def stat_section(heading: str, width: int | str):
    with col().classes(f"w-{width} gap-y-0").style("break-inside: avoid"):
        with row():
            ui.markdown(f"#### {heading}")
        with aligned_baseline_row():
            yield


async def sheet_view(sheet: CharacterSheet):
    calculator = DDBCharacterCalculator(sheet.last_loaded)
    # await combat_overview(calculator, sheet)
    # await combat_actions(calculator, sheet)
    await weapon_attacks(calculator, sheet)


class radio(ui.radio):
    def __init__(self):
        super().__init__({})
        self.classes("w-full")

    def __enter__(self):
        return self

    @contextlib.contextmanager
    def add_radio_item(self, key: int, selected=False):
        self.set_options(
            {**self.options, key: ""}, value=key if selected else self.value
        )
        with ui.teleport(
            f"#c{self.id} div:nth-child({len(self.options)})  .q-radio__label"
        ):
            yield


async def weapon_attacks(calculator: DDBCharacterCalculator, sheet: CharacterSheet):
    ui.markdown("# Weapon Attacks").style("break-before: page")
    with row().classes("pl-8"):
        with stat_section("Primary Hand", 80):
            with radio() as r:
                for weapon in calculator.weapons:
                    with r.add_radio_item(weapon.id):
                        with ui.grid(columns=3).classes("w-72 items-baseline"):
                            with ui.column():
                                ui.markdown(
                                    f"{weapon.definition.name} " + ""
                                    if not weapon.definition.canAttune
                                    else (
                                        "*Attuned*"
                                        if weapon.isAttuned
                                        else "*Not Attuned*"
                                    )
                                )
                            ui.label(weapon.definition.damage.diceString)
                            ui.label(weapon.definition.damageType)


async def combat_actions(calculator: DDBCharacterCalculator, sheet: CharacterSheet):
    ui.markdown("# Standard Combat Actions").style("break-before: page")

    with row().classes("pl-8"):
        with stat_section("Movement", 80):
            speeds = " ".join(f"**{name}** {v} ft" for name, v in calculator.speeds)
            ui.markdown(
                f"""
            {speeds}

            On your turn, you can move a distance up to your speed.  You may change your movement type as you do so, so
            long as your distance has not exceeded that movement's speed.  You may travel through the spaces of
            allies, Incapacitated creatures, or those two sizes greater or smaller than you.
            You can break up your movement on your turn, using some of your speed before and after your action.

            If you take the **Dash** action, you double your walk speed the current turn, including modifiers that reduce or increase it.
            If you have other speeds, you may double one of those as well, but you must specify which.

            If you take the **Disengage** action, your movement doesn't provoke Opportunity Attacks for the rest of the current turn.
            """
            )

        with stat_section("Attack / Magic", 80):
            ui.markdown(
                f"""
            When you take the **Magic** action, you cast a spell that has a casting time of an action
            or use a feature or magic item that requires a Magic action to be activated.  You can expend only one
            spell slot to cast a spell on your turn, and you may only maintain one Concentration spell at a time.

            While concentrating, you are at disadvantage to Wisdom ability rolls, and when you take damage, you must
            succeed a Constitution saving throw or lose concentration.  The DC is half the damage or 10, whichever
            is higher.

            When you take the **Attack** action, you make an attack roll with either a weapon or an unarmed free hand.
            As part of the Attack action, you may *either* equip or unequip *one* weapon, either by
            sheathing / unsheathing, or picking up / dropping.
            """
            )

        with stat_section("Dodge / Escape / Prone", 80):
            ui.markdown(
                f"""
            If you take the **Dodge** action, you gain the following benefits: until the start of your next turn, any attack roll made against you has Disadvantage if you can see the attacker, and you make Dexterity saving throws with Advantage.
            You lose these benefits if you have the Incapacitated condition or if your Speed is 0.

            If you take the **Escape** action, you my attempt a Strength or Dexterity saving throw against the grapple
            DC of one creature you is currently grappling you.  On success, that creature is no longer grappling you.
            As long as one creature remains grappling you, you have the Grappled condition.

            On your turn, you may give yourself the **Prone** condition as long as your speed is not 0.  You may remove
            your Prone condition by spending 15ft of movement.
            """
            )

        with stat_section("Hide / Search / Utilize", 80):
            ui.markdown(
                f"""
            If you take the **Hide** action, you make a Stealth roll ({calculator.calculate_skill_mod("stealth"):+})
            against a DC of 15. If you succeed and are either out of line of sight or heavily obscured for all enemies,
            you have the Invisible condition.

            The condition ends on you immediately after any of the following occurs: you make a sound louder than a
            whisper, an enemy finds you, you make an attack roll, or you cast a spell with a Verbal component.

            If you take the **Search** action, you make a Perception roll.  If your roll meets or exceeds
            the Stealth rolls of any nearby enemies you could hear or see, their Invisible condition ends.

            If you take the **Utilize** action, you may invoke the Utilize action associated with an item or
            an object within your reach.  Check item descriptions or ask the GM for how these actions might work.
            """
            )

        with stat_section("Help / Influence", 80):
            ui.markdown(
                f"""
            If you take the **Help** action, you give Advantage to the next attack roll by one of your allies
            against an enemy within 5 feet of you. This benefit expires at the start of your next turn.

            If you take the **Influence** action, you describe how your character makes a request of a target
            creature that can see or hear you.  If the target is unwilling, the action fails.  If the target is
            hesitant, you make a social skill roll against DC 15 or the target's intelligence score, whichever
            is higher.  On success, the target will attempt to comply with the request on its next action.

            If the target can hear and understand you, you may use Persuasion ({calculator.calculate_skill_mod("persuasion"):+})
            or Deception ({calculator.calculate_skill_mod("deception"):+}).
            If the target can hear you but not understand you, you may use Performance ({calculator.calculate_skill_mod("performance"):+})
            or Animal Handling ({calculator.calculate_skill_mod("animal handling"):+}).
            If the target can see you, you may use Intimidation ({calculator.calculate_skill_mod("intimidation"):+}).
            """
            )

        with stat_section("Grapple / Shove", 80):
            ui.markdown(
                f"""
            If you make an **unarmed attack** with a free hand, you may substitute that attack roll with either
            a grapple or a shove.  In either case, the target must roll a Strength or Dexterity saving throw against
            DC {calculator.grapple_dc}.

            For a **grapple**, a failure results in the target receiving the Grappled condition for as long as they remain
            within your reach, and your unarmed attack hand remains free.  A Grappled target has their speed set to
            zero, and they are disadvantage to attack any target that is not currently grappling them.

            For a **shove**, a failure results in the target either being knocked prone or pushed 5 feet away from you.
            """
            )


async def combat_overview(calculator: DDBCharacterCalculator, sheet: CharacterSheet):
    ui.markdown("# Combat Overview").style("break-before: page")
    armors = [armor_label(armor, calculator) for armor in calculator.armors] + [
        armor_label(None, calculator)
    ]
    short_col = with_classes(col, "w-10")
    with row().classes("pl-8"):
        with stat_section("HP", 60):
            with short_col():
                long_input(value=f"{sheet.current_hp}")
            with col():
                ui.label("(")
            with short_col():
                long_input(value=f"{sheet.temporary_hp}")
            with col():
                ui.label(")")
            with col():
                ui.label("/")
            with short_col():
                ui.label(f"{calculator.max_hp}")
        with stat_section("AC", 48):
            ui.select(armors, value=armor_label(sheet.current_armor, calculator))
        with stat_section("Initiative", 32):
            with short_col():
                long_input(value=f"{calculator.initiative}").disable()
        with stat_section("Saves", 40):
            with ui.grid(rows=2, columns=3).classes("gap-y-0 leading-none"):
                for idx, label in stat_name.items():
                    ui.markdown(
                        f"**{label.capitalize()[:3]}** {calculator.calculate_saving_throw(idx)}"
                    )

        if calculator.immunities:
            with stat_section("Immunities", 32):
                ui.label(", ".join(calculator.immunities))
        if calculator.resistances:
            with stat_section("Resistances", 32):
                ui.label(", ".join(calculator.resistances))
        with stat_section("Reactions", "full"):
            with col().classes("w-80"):
                ui.markdown(
                    calculator.apply_template_variables(
                        f"""
                    <ins>**Opportunity Attack**</ins>

                    When a creature that you can see leaves your reach on its turn or when using an action, a reaction, or its own movement, you may take a Reaction to make one melee attack against the provoking creature. The attack occurs right before the creature leaves your reach.
                """
                    )
                )
            for action_or_spell, class_spells in calculator.reactions:
                with col().classes("w-80"):
                    if isinstance(action_or_spell, Action):
                        ui.markdown(
                            calculator.apply_template_variables(
                                f"""
                            <ins>**{action_or_spell.name}**</ins>

                            {action_or_spell.snippet or action_or_spell.description or ''}
                        """
                            )
                        )
                    elif isinstance(action_or_spell, Spell):
                        ui.markdown(
                            calculator.apply_template_variables(
                                f"""
                            <ins>**{action_or_spell.definition.name}**</ins>

                            {action_or_spell.definition.snippet or action_or_spell.definition.description or ''}
                        """
                            )
                        )
