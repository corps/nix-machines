import contextlib
import json
import os.path

import aiohttp
import pytest
import sentry_sdk
from nicegui import Client, app, ui

from sheets.components import col, markdown, radio, row
from sheets.ddb import (
    CHARISMA,
    CONSTITUTION,
    DEXTERITY,
    INTELLIGENCE,
    STRENGTH,
    WISDOM,
    Action,
    Armor,
    ArmorType,
    ClassSpells,
    DDBCharacter,
    Item,
    Shield,
    Spell,
    Weapon,
    load_character,
    stat_name,
)
from sheets.storage import ModelStorage
from sheets.views.sheet_view.form import (
    Widths,
    _context,
    _Context,
    action_heading,
    apply_heading,
    blocked_overview,
    dice_input,
    name_input,
    set_edits,
    short_input,
    spell_heading,
    stat_section,
)
from sheets.views.sheet_view.sheet import CharacterSheet, sheet_storage


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
    except aiohttp.client.ClientError as e:
        sentry_sdk.capture_exception(e)
        character = character_storage.load(
            ddb_id, lambda: ui.notify("Cannot find character information.")
        )

    if character is None:
        return None

    ui.add_css(
        """
.q-radio, .q-radio__label {
    width: 100%
}
.nicegui-markdown ul {
    padding-inline-start: 0px !important
}
.clearfix:after {
  content:"";
  display:block;
  clear:both;
}
@page
{
    size: auto;
    margin: 0mm;
}"""
    )
    with ui.element().classes("container mx-auto max-w-2xl"):
        sheet_view(sheet, character)
    sheet_storage.store(ddb_id, sheet)
    # run_async_renderer(client, sheet_view(sheet))


character_storage = ModelStorage("character_", DDBCharacter, app.storage.general)


def describe_action(character: DDBCharacter, action: Action) -> tuple[str, str]:
    character.taken_actions.add(action)
    return action_heading(action), character.apply_template_variables(
        f"""
    <ins>**{action.name}**</ins>

    {action.snippet or action.description or ''}
    """,
        action.limitedUse,
        character.find_class_for(action),
        character.find_trait_for(action),
    )


def describe_spell(
    character: DDBCharacter, spell: Spell, class_spells: ClassSpells | None
) -> tuple[str, str]:
    character.taken_spells.add((spell, class_spells))
    return spell_heading(spell), character.apply_template_variables(
        f"""
    <ins>**{spell.definition.name}**</ins>
    {', '.join(c.name[0] for c in spell.definition.components)}
    {spell.definition.school}

    Cast Time: {spell.activation.activationTime} {spell.activation.activationType} {spell.definition.castingTimeDescription or ''}

    {spell.definition.snippet or spell.definition.description or ''}
    """,
        limited_use=spell.limitedUse,
        class_=character.find_class_for(class_spells),
        trait=None,
    )


def combat_overview(character: DDBCharacter):
    movement_overview(character)
    special_overview(character)
    reaction_overview(character)
    defensive_overview(character)
    weapons_overview(character)
    common_overview(character)
    actions_overview(character)


def weapons_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        with row().classes("justify-around mt-7"):
            mod = character.calculate_mod(STRENGTH)
            if character.unarmed_damage != "1":
                mod = max(mod, character.calculate_mod(DEXTERITY))
            dice_input("Grapple DC", 8 + mod + character.proficiency_modifier)
            dice_input("Prof", character.proficiency_modifier)
            dice_input(
                "Attacks", character.get_applied_modifier("extra-attacks", 0) + 1
            )
            dice_input("Str Mod", character.calculate_mod(STRENGTH))
            dice_input("Dex Mod", character.calculate_mod(DEXTERITY))

        with show_hand("Primary", character, character.weapons) as r:
            show_unarmed_strike(r, character)

        with show_hand("Off", character, character.weapons) as r:
            show_unarmed_strike(r, character)

        descriptions.append(
            (
                "Attacks",
                f"""
            ##### Attacks

            **Weapon Proficiencies:** {', '.join(character.weapon_proficiencies)}

            **Unarmed Strike** {character.unarmed_damage} Bludgeoning

            Any unarmed attack can be replaced with a unarmed maneuver: **Shove** or **Grapple**.
            A **Grapple** requires a free hand, which cannot hold anything else until the grapple ends.
            The target of an unarmed maneuver makes a Strength or Dexterity save to avoid its affect.
            You may move a target affected by your **Grapple** with you as you move for no extra cost.
            A target affected by your **Shove** may be knocked prone or moved 5 feet away from you.

            ##### Weapons

            * You can either equip or unequip one weapon each time you make an attack as part of the Attack action.
            * You do so either before or after the attack.
            """,
            )
        )


def movement_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        s = character.data.race.weightSpeeds.normal
        with row().classes("justify-around mt-7"):
            speed = character.get_applied_modifier("speed", s.walk)
            dice_input("Speed", value=speed)
            base_initiative = character.calculate_mod(DEXTERITY)
            bonus = character.get_applied_modifier("initiative", 0)
            dice_input("Initiative", value=base_initiative + bonus)

        unarmored_speed = character.get_applied_modifier("unarmored-movement", 0)
        if unarmored_speed:
            markdown(f"**unarmored speed - Bonus {unarmored_speed}**: always")

        descriptions.append(
            (
                "Movement",
                """
            ##### Movement

            * Move up to your speed on your turn.
            * Swimming, climbing, crawling, difficult terrain: cost twice movement.
            * Can pass through the spaces of allies, incapacitated, or two sizes greater or smaller than you.
            * Can break movement up between actions on your turn.
            * Use **Dash** action to double movement on your turn.
            * Use **Disengage** action to ignore enemy Opportunity Attacks on your turn.
            * Can fall prone on your turn for free, takes 15ft of movement to stand up.
            """,
            )
        )

    with blocked_overview(character) as descriptions:
        with row().classes("justify-around mt-7"):
            dice_input("Long", value=character.calculate_stat(STRENGTH))
            dice_input("Hi", value=character.calculate_mod(STRENGTH) + 3)

        descriptions.append(
            (
                "Jumping",
                """
            ##### Jumping

            * Jumped distance counts against speed on turn.
            * Requires 10 feet of movement, otherwise distance is half.
            """,
            )
        )


def common_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        with stat_section("Skills"):
            dice_input("Arcana", value=f"{character.calculate_skill_mod('arcana'):+}")
            dice_input(
                "Animal Handling",
                value=f"{character.calculate_skill_mod('animal handling'):+}",
            )
            dice_input(
                "Deception", value=f"{character.calculate_skill_mod('deception'):+}"
            )
            dice_input("History", value=f"{character.calculate_skill_mod('history'):+}")
            dice_input("Insight", value=f"{character.calculate_skill_mod('insight'):+}")
            dice_input(
                "Intimidation",
                value=f"{character.calculate_skill_mod('intimidation'):+}",
            )
            dice_input(
                "Investigation",
                value=f"{character.calculate_skill_mod('investigation'):+}",
            )
            dice_input("Nature", value=f"{character.calculate_skill_mod('nature'):+}")
            dice_input(
                "Perception", value=f"{character.calculate_skill_mod('perception'):+}"
            )
            dice_input(
                "Performance", value=f"{character.calculate_skill_mod('performance'):+}"
            )
            dice_input(
                "Persuasion", value=f"{character.calculate_skill_mod('persuasion'):+}"
            )
            dice_input(
                "Religion", value=f"{character.calculate_skill_mod('religion'):+}"
            )
            dice_input("Stealth", value=f"{character.calculate_skill_mod('stealth'):+}")
            dice_input(
                "Survival", value=f"{character.calculate_skill_mod('survival'):+}"
            )
            stealth_dis_item_names = [
                i.definition.name
                for i in character.data.inventory
                if i.definition.stealthCheck == 2
            ]
            if stealth_dis_item_names:
                markdown(
                    f"**disadvantage stealth**: when ({', '.join(stealth_dis_item_names)}) equipped"
                )

        descriptions.append(
            (
                "Influence",
                """
            ##### Influence

            * Take the **Influence** action to direct an enemy's action
            * Describe how and what you would like to influence about an enemy's turn.
            * If the target would be hesitant to take the action, roll against a DC 15.
            * On success, the target attempts to abide by your influence on their next turn.
            """,
            )
        )

        descriptions.append(
            (
                "Stealth",
                """
            ##### Help

            * Take **Help** action to distract an enemy within 5 feet of you.
            * Next Ally's attack against that enemy is at advantage.
            * Expires at the start of your next turn, or if your speed is reduced to 0.
            """,
            )
        )

    with blocked_overview(character) as descriptions:
        markdown(
            f"""
            ##### Hide

            * You may take the **Hide** action to attempt to gain the Invisible condition.
            * You must be in either 3/4 cover or Heavily Obscured area.
            * Roll a Stealth check against DC 15.  On success, you gain the Invisible condition.  **Note your result total.**
            * Condition breaks if you make a sound louder than a whisper, an enemy finds you, make an attack roll, or use a Verbal component.
            """
        )

        descriptions.append(
            (
                "Help",
                """
            ##### Search

            * You may take the **Search** action to use a Wisdom skill roll to ascertain hidden physical clues. Insight, Medicine, Perception, Survival are valid skills.
            * When using *Perception*, you break the Invisible condition of any creatures whose Stealth check result was less than or equal to your result.

            ##### Study

            * Take **Study** action to use an Intelligence skill roll to ascertain hidden knowledge clues.  Arcana, History, Investigation, Nature, Religion are valid skills.
            """,
            )
        )


def special_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        descriptions.append(
            (
                "Features",
                """
            ##### Features

            * Features are unique exceptions to rules that govern your character.
            * Read them carefully, they apply in special cases that you are responsible for tracking!
            """,
            )
        )
        for action, class_spells in character.special_actions:
            if isinstance(action, Action):
                descriptions.append(describe_action(character, action))
            elif isinstance(action, Spell):
                descriptions.append(describe_spell(character, action, class_spells))

        for feature_name in ["Fighting Style", "Weapon Mastery"]:
            for option in character.find_options_of_feature(feature_name):
                if option.definition.activation:
                    continue
                descriptions.append(
                    (
                        f"Option/{option.definition.id}",
                        f"""
                    **{option.definition.name}**

                    {character.apply_template_variables(option.definition.description, None, None, None)}
                    """,
                    )
                )

        for feat in character.data.feats:
            descriptions.append(
                (
                    f"Feat/{feat.definition.id}",
                    f"""
                **{feat.definition.name}**

                {feat.definition.snippet or feat.definition.description or ''}
                """,
                )
            )


def reaction_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        with stat_section("Ready"):
            markdown(
                """
            * You may use your reaction to **Ready** an action for outside your turn.
            * Specify a trigger you can see or hear.
            * Specify an Action or Spell you wish to execute.
            * Readying a spell requires concentration until the trigger.
            * The first time your trigger condition is satisfied, you must either commit or cancel.
            """
            )

        descriptions.append(
            (
                "Reactions",
                """
             ##### Reactions

             * You may a take a reaction on your or any other turn.
             * You may not use another reaction until the start of your next turn.
             """,
            )
        )

        descriptions.append(
            (
                "Opportunity Attack",
                """
            <ins>**Opportunity Attack**</ins>

            You can take a Reaction to make an Opportunity Attack when a creature that you can see leaves your reach using its action,
            its Bonus Action, its Reaction, or uses its standard movement.  To do so, make one melee attack with a weapon or an Unarmed Strike against the provoking creature.
            The attack occurs right before the creature leaves your reach.
            """,
            )
        )

        for action, class_spells in character.reactions:
            if isinstance(action, Action):
                descriptions.append(describe_action(character, action))
            elif isinstance(action, Spell):
                descriptions.append(describe_spell(character, action, class_spells))


@contextlib.contextmanager
def show_hand(hand: str | list[str], character: DDBCharacter, items: list[Item]):
    with stat_section(f"{hand} Hand"):
        with set_edits(apply_heading(radio(), "Body")) as r:
            for item in items:
                with r.add_radio_item(item.id), apply_heading(row(), f"{item.id}"):
                    with row():
                        if isinstance(item, Shield):
                            character.taken_items.add(item)
                            with col():
                                name_input("Name", item.definition.name)
                            with col():
                                short_input(
                                    "AC",
                                    (
                                        item.definition.armorClass
                                        + item.definition.magic_modifier
                                        if "shields" in character.profencies
                                        else 0
                                    ),
                                )
                        if isinstance(item, Weapon):
                            character.taken_items.add(item)
                            stats = ", ".join(stat_name[o] for o in item.stat_options)
                            with col():
                                name_input("Name", item.definition.name)
                            with col():
                                dice_input("Stat", stats)
            yield r


def show_unarmed_strike(r: radio, character: DDBCharacter):
    with r.add_radio_item():
        with row():
            stats = ", ".join(stat_name[o] for o in character.unarmed_stats)
            name_input("Name", "Unarmed")
            dice_input("Stat", stats)


def defensive_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        with stat_section("HP"):
            dice_input("Current", value=character.cur_hp)
            dice_input("Temp", value=character.temp_hp)
            dice_input("Max", value=character.max_hp)

        with stat_section("Saves"):
            with row().classes("justify-around"):
                short_input("Str", character.calculate_saving_throw(STRENGTH))
                short_input("Dex", character.calculate_saving_throw(DEXTERITY))
                short_input("Con", character.calculate_saving_throw(CONSTITUTION))

            with row().classes("justify-around"):
                short_input("Int", character.calculate_saving_throw(INTELLIGENCE))
                short_input("Wis", character.calculate_saving_throw(WISDOM))
                short_input("Cha", character.calculate_saving_throw(CHARISMA))

        descriptions.append(
            (
                "Defense",
                f"""
            ##### Dodge

            * You may take the **Dodge** action to impose disadvantage on attacks you can see and gain advantage on Dexterity saves
            * Ends on the start of your next turn, when you are incapacitated, or when your speed is reduced to 0.

            ##### Escape

            * You may take the **Escape** action to attempt to escape one grappler
            * You make Strength or Dexterity save against target's grapple DC
            * As long as any creature is grappling you, you still have the Grappled condition
            """,
            )
        )

    with blocked_overview(character) as descriptions:
        with stat_section("Body"):
            with set_edits(radio()) as r:
                for armor in character.armors:
                    character.taken_items.add(armor)
                    if character.calculate_stat(STRENGTH) < (
                        armor.definition.strengthRequirement or 0
                    ):
                        continue

                    with r.add_radio_item(armor.id), apply_heading(
                        row(), f"{armor.id}"
                    ):
                        name_input("Name", armor.definition.name)
                        base = (
                            armor.definition.armorClass
                            + armor.definition.magic_modifier
                        )
                        mod = character.calculate_mod(DEXTERITY)
                        if armor.max_dex_modifier is not None:
                            mod = min(armor.max_dex_modifier, mod)
                        short_input("AC", base + mod)

                with r.add_radio_item(), apply_heading(row(), "Unarmored"):
                    name_input("Name", "Unarmored")
                    base = character.get_applied_modifier("unarmored-armor-class", 0)
                    base = 10 + base
                    mod = character.calculate_mod(DEXTERITY)
                    short_input("AC", base + mod)

            for m in character.all_modifiers:
                if m.type == "ignore" and m.subType == "heavy-armor-speed-reduction":
                    markdown("*Ignore Heavy Armor Speed Reduction*")

        with show_hand("Off", character, character.shields):
            pass

        if character.resistances:
            markdown(f"**Resistances**: {', '.join(character.resistances)}")
        if character.immunities:
            markdown(f"**Immunities**: {', '.join(character.immunities)}")

        descriptions.append(
            (
                "Armor",
                f"""
            ##### Armor

            **Armor Proficiencies**: {', '.join(str(at) for at in ArmorType if at.proficiency in character.profencies)}

            **Shield Proficiency**: {"yes" if "shields" in character.profencies else "no"}
            """,
            )
        )


def sheet_view(sheet: CharacterSheet, character: DDBCharacter):
    _context.set(_Context(sheet=sheet))
    with stat_section("Combat Overview"):
        combat_overview(character)
    sheet.complete_form()
    pass


@pytest.mark.asyncio
async def test_get_characters():
    # for ddb_id in (45344354, 112315775, 132574960, 132651573):
    for ddb_id in (132651573,):
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

        unused = set(character.all_modifiers)
        unused -= character.taken_modifiers
        assert not unused


def actions_overview(character: DDBCharacter):
    with blocked_overview(character) as descriptions:
        descriptions.append(
            (
                "Actions",
                """
            ##### Actions

            * One action per turn, unless a special rule allows otherwise.
            * You may also take one *Bonus Action* per turn.  However, anything that deprives you of your ability to take actions also prevents you from taking a Bonus Action.
            """,
            )
        )
        for action, class_spells in character.actions:
            if isinstance(action, Action):
                descriptions.append(describe_action(character, action))
            elif isinstance(action, Spell):
                descriptions.append(describe_spell(character, action, class_spells))
