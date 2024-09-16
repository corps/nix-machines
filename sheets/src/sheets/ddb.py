import dataclasses
import json
import math
import re
from enum import IntEnum
from functools import cached_property
from typing import Literal, TypeVar

import aiohttp
import pytest
from nicegui import ui
from pydantic import BaseModel, Field, ValidationError

_M = TypeVar("_M", bound=BaseModel)


class Modifier(BaseModel):
    type: str
    subType: str | None
    statId: int | None
    requiresAttunement: bool | None
    value: int | None


class Activation(BaseModel):
    activationTime: int | None
    activationType: "ActivationType | None"


class Range(BaseModel):
    origin: str | None = None
    rangeValue: int | None = None
    aoeType: str | None = None
    aoeValue: int | None = None


class Property(BaseModel):
    id: int
    name: str
    description: str
    notes: str | None


class Item(BaseModel):
    id: int

    class Definition(BaseModel):
        id: int

        class Damage(BaseModel):
            diceString: str

        filterType: str
        name: str
        canEquip: bool
        magic: bool
        description: str
        canAttune: bool
        weight: float
        stackable: bool
        isConsumable: bool
        baseItemId: int | None
        baseArmorName: str | None
        armorClass: int | None
        stealthCheck: int | None
        damage: Damage | None
        damageType: str | None
        fixedDamage: None
        attackType: int | None
        range: int | None
        longRange: int | None
        isMonkWeapon: bool | None
        armorTypeId: int | None
        isContainer: bool
        properties: list[Property] | None

        class GrantedModifier(BaseModel):
            type: str
            subType: str
            value: int

        grantedModifiers: list[GrantedModifier] | None

    definition: Definition
    equipped: bool
    chargesUsed: int
    isAttuned: bool
    quantity: int


class Armor(Item):
    class ArmorDefinition(Item.Definition):
        filterType: Literal["Armor"]
        armorClass: int
        armorTypeId: int
        properties: list[Property]

    definition: ArmorDefinition


class Weapon(Item):
    class WeaponDefinition(Item.Definition):
        filterType: Literal["Weapon"]
        damageType: str
        damage: Item.Definition.Damage
        properties: list[Property]

    definition: WeaponDefinition


class Trait(BaseModel):
    class Definition(BaseModel):
        name: str
        description: str
        snippet: str | None
        hideInBuilder: bool
        hideInSheet: bool
        activation: Activation | None
        requiredLevel: int | None

    definition: Definition


class Stat(BaseModel):
    id: int
    name: str | None
    value: int | None


class Component(IntEnum):
    SOMATIC = 1
    VERBAL = 2
    MATERIAL = 3


class Spell(BaseModel):
    overrideSaveDc: int | None

    class LimitedUse(BaseModel):
        resetType: int | None
        numberUsed: int
        minNumberConsumed: int | None
        maxNumberConsumed: int | None
        maxUses: int

    limitedUse: LimitedUse | None

    class Defintion(BaseModel):
        id: int
        name: str
        level: int
        school: str

        class Duration(BaseModel):
            durationInterval: int | None
            durationUnit: str | None
            durationType: str | None

        description: str
        snippet: str
        components: list[Component]
        duration: Duration
        activation: Activation
        concentration: bool
        ritual: bool
        componentsDescription: str
        saveDcAbilityId: int | None
        tags: list[str]
        asPartOfWeaponAttack: bool
        overrideSaveDc: int | None = None

    definition: Defintion

    prepared: bool
    countsAsKnownSpell: bool | None
    usesSpellSlot: bool
    castAtLevel: int | None
    alwaysPrepared: bool
    displayAsAttack: bool | None
    castOnlyAsRitual: bool
    range: Range
    activation: Activation


class Action(BaseModel):
    class Dice(BaseModel):
        diceCount: int
        diceValue: int
        diceString: str

    name: str
    description: str | None
    snippet: str | None
    actionType: int
    activation: Activation
    range: Range
    abilityModifierStatId: int | None
    onMissDescription: str | None
    saveFailDescription: str | None
    saveSuccessDescription: str | None
    saveStatId: int | None
    fixedSaveDc: int | None
    attackTypeRange: None
    dice: Dice | None
    displayAsAttack: bool | None


class DDBCharacter(BaseModel):
    id: int
    success: bool
    message: str

    class Data(BaseModel):
        id: int
        userId: int
        username: str
        isAssignedToPlayer: bool
        readonlyUrl: str

        class Decorations(BaseModel):
            avatarUrl: str | None = None
            frameAvatarUrl: str | None = None
            backdropAvatarUrl: str | None = None
            smallBackdropAvatarUrl: str | None = None
            largeBackdropAvatarUrl: str | None = None
            thumbnailBackdropAvatarUrl: str | None = None

        decorations: Decorations
        name: str
        inspiration: bool
        baseHitPoints: int
        bonusHitPoints: int | None
        overrideHitPoints: int | None
        removedHitPoints: int
        temporaryHitPoints: int
        lifestyleId: int | None

        stats: list[Stat]
        bonusStats: list[Stat]
        overrideStats: list[Stat]

        class Race(BaseModel):
            fullName: str
            racialTraits: list[Trait]

            class WeightSpeeds(BaseModel):
                class Speeds(BaseModel):
                    walk: int
                    fly: int
                    burrow: int
                    swim: int
                    climb: int

                normal: Speeds

            weightSpeeds: WeightSpeeds

        race: Race
        inventory: list[Item]

        class Currencies(BaseModel):
            cp: int
            sp: int
            gp: int
            ep: int
            pp: int

        currencies: Currencies

        class Class(BaseModel):
            class Definition(BaseModel):
                name: str

                class SpellRules(BaseModel):
                    isRitualSpellCaster: bool
                    levelPreparedSpellMaxes: list[int | None]

                spellRules: SpellRules

            classFeatures: list[Trait]
            level: int
            definition: Definition

        classes: list[Class]

        class Feat(BaseModel):
            class Definition(BaseModel):
                name: str
                description: str
                snippet: str | None

            definition: Definition

        feats: list[Feat]

        class SpellSlot(BaseModel):
            level: int
            used: int
            available: int

        spellSlots: list[SpellSlot]
        pactMagic: list[SpellSlot]

        class Spells(BaseModel):
            race: list[Spell]
            background: list[Spell] | None
            item: list[Spell] | None
            feat: list[Spell] | None
            class_: list[Spell] | None = Field(alias="class")

        spells: Spells

        class Actions(BaseModel):
            race: list[Action] | None
            class_: list[Action] | None = Field(alias="class")
            background: list[Action] | None
            item: list[Action] | None
            feat: list[Action] | None

        actions: Actions

        class ClassSpells(BaseModel):
            spells: list[Spell]

        classSpells: list[ClassSpells]

        class Modifiers(BaseModel):
            race: list[Modifier] | None
            class_: list[Modifier] | None = Field(alias="class")
            background: list[Modifier]
            item: list[Modifier]
            feat: list[Modifier]
            condition: list[Modifier] | None

        modifiers: Modifiers

    data: Data


async def load_character(character_id: int) -> DDBCharacter:
    async with aiohttp.ClientSession() as session:
        res = await session.get(
            f"https://character-service.dndbeyond.com/character/v5/character/{character_id}"
        )
        res.raise_for_status()
        json_body = await res.json()
        with open(f"character.{character_id}.json", "w") as f:
            f.write(json.dumps(json_body, indent=2))

        try:
            return DDBCharacter.model_validate(json_body)
        except ValidationError as err:
            print(err.errors())
            raise err


STRENGTH = 0
DEXTERITY = 1
CONSTITUTION = 2
INTELLIGENCE = 3
WISDOM = 4
CHARISMA = 5
stat_name = {
    STRENGTH: "strength",
    DEXTERITY: "dexterity",
    CONSTITUTION: "constitution",
    INTELLIGENCE: "intelligence",
    WISDOM: "wisdom",
    CHARISMA: "charisma",
}
skills = {
    "acrobatics": DEXTERITY,
    "animal handling": WISDOM,
    "arcana": INTELLIGENCE,
    "athletics": STRENGTH,
    "deception": WISDOM,
    "history": INTELLIGENCE,
    "insight": WISDOM,
    "intimidation": CHARISMA,
    "investigation": INTELLIGENCE,
    "medicine": WISDOM,
    "nature": INTELLIGENCE,
    "perception": WISDOM,
    "performance": CHARISMA,
    "persuasion": CHARISMA,
    "religion": INTELLIGENCE,
    "sleight of hand": DEXTERITY,
    "stealth": DEXTERITY,
    "survival": WISDOM,
}


class ActivationType(IntEnum):
    REACTION = 4
    BONUS_ACTION = 3
    ACTION = 1
    RIDER = 8


@dataclasses.dataclass
class DDBCharacterCalculator:
    character: DDBCharacter

    def calculate_stat(self, index: int):
        if self.character.data.overrideStats[index].value:
            return self.character.data.overrideStats[index].value
        return (
            self.character.data.stats[index].value
            + (self.character.data.bonusStats[index].value or 0)
            + sum(
                m.value
                for m in self.all_modifiers
                if m.value
                and m.type == "bonus"
                and m.subType == stat_name[index] + "-score"
            )
        )

    def calculate_mod(self, index: int):
        return math.floor((self.calculate_stat(index) - 10) / 2)

    @property
    def proficiency_modifier(self):
        if self.levels < 5:
            return 2
        if self.levels < 9:
            return 3
        if self.levels < 13:
            return 4
        if self.levels < 17:
            return 5
        return 6

    def calculate_saving_throw(self, index: int):
        return self.calculate_mod(index) + self.calculate_prof_modifier(
            f"{stat_name[index]}-saving-throws"
        )

    def calculate_skill_mod(self, skill: str):
        return self.calculate_mod(skills[skill]) + self.calculate_prof_modifier(
            skill.replace(" ", "-")
        )

    def calculate_weapon_best_stat(self, weapon: Weapon) -> int:
        properties_ = [p.name for p in weapon.definition.properties]
        if "Finesse" in properties_:
            if self.calculate_stat(STRENGTH) > self.calculate_stat(DEXTERITY):
                return STRENGTH
            return DEXTERITY
        if "Thrown" in properties_:
            return STRENGTH
        if weapon.definition.longRange > 5 and "Reach" not in properties_:
            return DEXTERITY
        return STRENGTH
        # https://github.com/MrPrimate/ddb-importer/blob/main/src/parser/item/weapon.js

    @property
    def grapple_dc(self) -> int:
        return 8 + self.calculate_mod(STRENGTH) + self.proficiency_modifier

    @property
    def speeds(self) -> list[tuple[str, int]]:
        s = self.character.data.race.weightSpeeds.normal
        return [
            (k, v)
            for k, v in (
                ("walk", s.walk),
                ("burrow", s.burrow),
                ("fly", s.fly),
                ("swim", s.swim),
                ("long jump", self.calculate_stat(STRENGTH)),
                ("hi jump", self.calculate_mod(STRENGTH) + 3),
            )
            if v
        ]

    def apply_template_variables(self, s: str):
        template = re.compile(r"\{\{.*}}", re.DOTALL)
        pos = 0
        match = template.search(s, pos)
        while match:
            pos = match.end()
            if match[0] == "{{proficiency#signed}}":
                s = s[: match.start()] + "+" + str(self.proficiency_modifier) + s[pos:]
            match = template.search(s, pos)
        return s

    @cached_property
    def reactions(
        self,
    ) -> list[tuple[Action, None] | tuple[Spell, DDBCharacter.Data.ClassSpells]]:
        return [
            *(
                (action, None)
                for action in self.character.data.actions.race or []
                if action.activation.activationType == ActivationType.REACTION
            ),
            *(
                (action, None)
                for action in self.character.data.actions.feat or []
                if action.activation.activationType == ActivationType.REACTION
            ),
            *(
                (action, None)
                for action in self.character.data.actions.item or []
                if action.activation.activationType == ActivationType.REACTION
            ),
            *(
                (action, None)
                for action in self.character.data.actions.background or []
                if action.activation.activationType == ActivationType.REACTION
            ),
            *(
                (action, None)
                for action in self.character.data.actions.class_ or []
                if action.activation.activationType == ActivationType.REACTION
            ),
            *(
                (spell, class_spells)
                for class_spells in self.character.data.classSpells
                for spell in class_spells.spells
                if spell.activation.activationType == ActivationType.REACTION
            ),
        ]

    def calculate_prof_modifier(self, proficiency: str) -> int:
        if proficiency in self.expertise:
            return self.proficiency_modifier * 2
        if proficiency in self.profencies:
            return self.proficiency_modifier
        return 0

    @cached_property
    def profencies(self):
        return [m.subType for m in self.all_modifiers if m.type == "proficiency"]

    @cached_property
    def expertise(self):
        return [m.subType for m in self.all_modifiers if m.type == "expertise"]

    @cached_property
    def levels(self):
        return sum(c.level for c in self.character.data.classes)

    @cached_property
    def max_hp(self):
        if self.character.data.overrideHitPoints is not None:
            return self.character.data.overrideHitPoints
        return (
            self.character.data.baseHitPoints
            + (self.character.data.bonusHitPoints or 0)
            + (self.calculate_mod(CONSTITUTION) * self.levels)
        )

    @cached_property
    def cur_hp(self):
        return self.max_hp - self.character.data.removedHitPoints

    @cached_property
    def temp_hp(self):
        return self.character.data.temporaryHitPoints

    @cached_property
    def ac(self):
        return self.effective_ac(self.current_armor)

    @cached_property
    def armors(self) -> list[Armor]:
        return self.filter(self.character.data.inventory, Armor)

    @cached_property
    def weapons(self) -> list[Weapon]:
        return self.filter(self.character.data.inventory, Weapon)

    @cached_property
    def current_armor(self) -> Armor | None:
        for a in self.armors:
            if a.equipped:
                return a
        return None

    @cached_property
    def all_modifiers(self) -> list[Modifier]:
        return [
            *(self.character.data.modifiers.feat or []),
            *(self.character.data.modifiers.item or []),
            *(self.character.data.modifiers.race or []),
            *(self.character.data.modifiers.background or []),
            *(self.character.data.modifiers.class_ or []),
        ]

    def effective_ac(self, armor: Armor | None):
        result = self.calculate_mod(DEXTERITY)
        if armor is None:
            result += 10
        else:
            if armor.definition.armorTypeId == 2:
                result = min(result, 2)
            result += armor.definition.armorClass
        return result

    @property
    def initiative(self):
        return self.calculate_mod(DEXTERITY)

    @cached_property
    def immunities(self):
        return [m.subType for m in self.all_modifiers if m.type == "immunity"]

    @cached_property
    def resistances(self):
        return [m.subType for m in self.all_modifiers if m.type == "resistance"]

    def filter(self, inputs: list[BaseModel], t: type[_M]) -> list[_M]:
        result = []
        for i in inputs:
            try:
                result.append(t.model_validate(i.model_dump()))
            except ValidationError:
                continue
        return result


class CharacterSheet(BaseModel):
    last_loaded: DDBCharacter

    current_hp: int = -1
    temporary_hp: int = -1
    current_armor: Armor | None = None


async def load_sheet(character_id: int) -> CharacterSheet:
    ddb_character = await load_character(character_id)
    calculator = DDBCharacterCalculator(ddb_character)
    return CharacterSheet(
        last_loaded=ddb_character,
        current_hp=calculator.cur_hp,
        temporary_hp=calculator.temp_hp,
        current_armor=calculator.current_armor,
    )


async def update_sheet(sheet: CharacterSheet):
    ddb_character = await load_character(sheet.last_loaded.data.id)
    calculator = DDBCharacterCalculator(ddb_character)
    if calculator.cur_hp != sheet.current_hp:
        sheet.current_hp = calculator.cur_hp
    if calculator.temp_hp != sheet.temporary_hp:
        sheet.temporary_hp = calculator.temp_hp
    if calculator.current_armor != sheet.current_armor:
        sheet.current_armor = calculator.current_armor
    sheet.last_loaded = ddb_character


@pytest.mark.asyncio
async def test_get_characters():
    character = await load_character(45344354)
    DDBCharacter.model_validate(character.model_dump(mode="json", by_alias=True))
