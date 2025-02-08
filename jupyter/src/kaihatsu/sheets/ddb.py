import json
import math
import re
from enum import IntEnum
from functools import cached_property
from typing import Any, Callable, Literal, TypeVar

import requests
from pydantic import BaseModel, Field, ValidationError

_M = TypeVar("_M", bound=BaseModel)


class Ability(IntEnum):
    STRENGTH = 0
    DEXTERITY = 1
    CONSTITUTION = 2
    INTELLIGENCE = 3
    WISDOM = 4
    CHARISMA = 5

    @classmethod
    def by_short_name(cls, name: str) -> "Ability":
        for ability in cls:
            if ability.name.lower()[:3] == name.lower():
                return ability
        raise ValueError(f"Unknown ability name: {name}")


skills = {
    "acrobatics": Ability.DEXTERITY,
    "animal handling": Ability.WISDOM,
    "arcana": Ability.INTELLIGENCE,
    "athletics": Ability.STRENGTH,
    "deception": Ability.WISDOM,
    "history": Ability.INTELLIGENCE,
    "insight": Ability.WISDOM,
    "intimidation": Ability.CHARISMA,
    "investigation": Ability.INTELLIGENCE,
    "medicine": Ability.WISDOM,
    "nature": Ability.INTELLIGENCE,
    "perception": Ability.WISDOM,
    "performance": Ability.CHARISMA,
    "persuasion": Ability.CHARISMA,
    "religion": Ability.INTELLIGENCE,
    "sleight of hand": Ability.DEXTERITY,
    "stealth": Ability.DEXTERITY,
    "survival": Ability.WISDOM,
}


class ActivationType(IntEnum):
    REACTION = 4
    BONUS_ACTION = 3
    ACTION = 1
    LONG_CAST = 6
    REST = 7
    RIDER = 8

    def __str__(self):
        return self.name.lower().capitalize()


def parse_formula_tokens(i: str) -> list[str]:
    return re.findall(r"\(|\)|\+|\*|[a-z:]*|[0-9]*", i)


class Modifier(BaseModel, frozen=True):
    id: str
    type: str
    subType: str | None
    statId: int | None
    restriction: str | None
    requiresAttunement: bool | None
    value: int | None
    bonusTypes: tuple[int, ...] | None
    friendlyTypeName: str
    friendlySubtypeName: str


class AppliedModifier(Modifier, frozen=True):
    id: str
    type: Literal["set", "bonus"]
    subType: str
    requiresAttunement: Literal[False] | None


class LeverageModifier(Modifier, frozen=True):
    id: str
    type: Literal["advantage", "disadvantage"]
    subType: str
    statId: None
    restriction: str
    requiresAttunement: Literal[False] | None
    value: None


class Activation(BaseModel, frozen=True):
    activationTime: int | None
    activationType: "ActivationType | None"


class Range(BaseModel, frozen=True):
    origin: str | None = None
    rangeValue: int | None = None
    aoeType: str | None = None
    aoeValue: int | None = None

    def __str__(self):
        return " ".join(
            str(p)
            for p in (self.origin, self.rangeValue, self.aoeType, self.aoeValue)
            if p
        )


class Property(BaseModel, frozen=True):
    id: int
    name: str
    description: str
    notes: str | None


class Item(BaseModel):
    id: int

    class Definition(BaseModel):
        id: int

        class Damage(BaseModel, frozen=True):
            diceString: str

            def __str__(self):
                return f"{self.diceString}"

        filterType: str
        name: str
        type: str | None
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
        properties: tuple[Property, ...] | None
        strengthRequirement: int | None

        class GrantedModifier(BaseModel, frozen=True):
            type: str
            subType: str
            value: int | None

        grantedModifiers: tuple[GrantedModifier, ...] | None

        @property
        def magic_modifier(self):
            return max(
                (m.value or 0 for m in self.grantedModifiers if m.subType == "magic"),
                default=0,
            )

    definition: Definition
    equipped: bool
    chargesUsed: int
    isAttuned: bool
    quantity: int


class Shield(Item, frozen=True):
    class ShieldDefinition(Item.Definition, frozen=True):
        canEquip: Literal[True]
        armorClass: int
        armorTypeId: Literal[4]

    definition: ShieldDefinition


class ArmorType(IntEnum):
    LIGHT = 1
    MEDIUM = 2
    HEAVY = 3

    def __str__(self):
        return self.name.lower().capitalize()

    @property
    def proficiency(self):
        if self == ArmorType.LIGHT:
            return "light-armor"
        if self == ArmorType.MEDIUM:
            return "medium-armor"
        return "heavy-armor"


class Armor(Item, frozen=True):
    class ArmorDefinition(Item.Definition, frozen=True):
        canEquip: Literal[True]
        armorClass: int
        armorTypeId: ArmorType

    definition: ArmorDefinition

    @property
    def max_dex_modifier(self) -> int | None:
        if self.definition.armorTypeId == ArmorType.HEAVY:
            return 0
        if self.definition.armorTypeId == ArmorType.MEDIUM:
            return 2
        return None


class WeaponProperty(BaseModel, frozen=True):
    name: str
    description: str


class Weapon(Item, frozen=True):
    class WeaponDefinition(Item.Definition, frozen=True):
        filterType: Literal["Weapon"]
        damageType: str
        damage: Item.Definition.Damage
        properties: tuple[WeaponProperty, ...]
        range: int
        longRange: int

    @property
    def stat_options(self) -> list[int]:
        properties_ = [p.name for p in self.definition.properties]
        if "Finesse" in properties_:
            return [Ability.STRENGTH, Ability.DEXTERITY]
        if "Thrown" in properties_:
            return [Ability.STRENGTH]
        if self.definition.longRange > 5 and "Reach" not in properties_:
            return [Ability.DEXTERITY]
        return [Ability.STRENGTH]

    definition: WeaponDefinition


class Trait(BaseModel):
    class Definition(BaseModel):
        id: int
        name: str
        description: str
        snippet: str | None
        hideInBuilder: bool
        hideInSheet: bool
        activation: Activation | None
        requiredLevel: int | None

        class LevelScaler(BaseModel):
            level: int
            description: str
            dice: "Dice | None"
            fixedValue: int | None

        levelScales: list[LevelScaler] | None = None

        class GrantedFeat(BaseModel):
            name: str
            featIds: list[int]

        grantedFeats: list[GrantedFeat] | None = None

    definition: Definition

    def scaler(self, level: int) -> str | None:
        for scaler in reversed(self.definition.levelScales):
            if level >= scaler.level:
                return scaler.dice.diceString or scaler.fixedValue


class Stat(BaseModel):
    id: int
    name: str | None
    value: int | None


class Component(IntEnum):
    SOMATIC = 1
    VERBAL = 2
    MATERIAL = 3


class ResetType(IntEnum):
    SHORT_REST = 1
    LONG_REST = 2

    def __str__(self):
        if self == ResetType.LONG_REST:
            return "/ Long Rest"
        elif self == ResetType.SHORT_REST:
            return "/ Short Rest"
        return ""


class LimitedUse(BaseModel, frozen=True):
    resetType: ResetType | None
    numberUsed: int
    minNumberConsumed: int | None
    maxNumberConsumed: int | None
    maxUses: int
    proficiencyBonusOperator: int | None
    useProficiencyBonus: bool | None

    def max_uses(self, character: "DDBCharacter"):
        if self.proficiencyBonusOperator is not None and self.useProficiencyBonus:
            if self.proficiencyBonusOperator == 1:
                return self.maxUses + character.proficiency_modifier
        return self.maxUses


class Dice(BaseModel, frozen=True):
    diceCount: int | None
    diceValue: int | None
    diceString: str | None

    def __bool__(self):
        return (
            self.diceCount is not None
            or self.diceValue is not None
            or self.diceString is not None
        )


class Spell(BaseModel, frozen=True):
    overrideSaveDc: int | None

    limitedUse: LimitedUse | None

    class Definition(BaseModel, frozen=True):
        id: int
        name: str
        level: int
        school: str

        class Duration(BaseModel, frozen=True):
            durationInterval: int | None
            durationUnit: str | None
            durationType: str | None

            def __str__(self):
                return " ".join(
                    str(p)
                    for p in (
                        self.durationInterval,
                        self.durationUnit,
                        self.durationType,
                    )
                    if p
                )

        description: str
        snippet: str
        components: tuple[Component, ...]
        duration: Duration
        activation: Activation
        castingTimeDescription: str | None
        concentration: bool
        ritual: bool
        componentsDescription: str
        saveDcAbilityId: int | None
        tags: tuple[str, ...]
        asPartOfWeaponAttack: bool
        overrideSaveDc: int | None = None

    definition: Definition

    prepared: bool
    countsAsKnownSpell: bool | None
    usesSpellSlot: bool
    castAtLevel: int | None
    alwaysPrepared: bool
    displayAsAttack: bool | None
    castOnlyAsRitual: bool
    range: Range
    activation: Activation


class Action(BaseModel, frozen=True):
    id: str
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
    attackTypeRange: int | None
    dice: Dice | None
    displayAsAttack: bool | None
    limitedUse: "LimitedUse | None"
    componentId: int


class ClassSpells(BaseModel):
    spells: list[Spell]
    characterClassId: int


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

        class OptionSet(BaseModel):
            class Option(BaseModel, frozen=True):
                class Definition(BaseModel, frozen=True):
                    id: int
                    name: str
                    description: str
                    activation: Activation | None

                definition: Definition
                componentId: int

            race: list[Option]
            class_: list[Option] = Field(alias="class")
            background: list[Option] | None
            item: list[Option] | None
            feat: list[Option] | None

        options: OptionSet

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
                id: int
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
                id: int
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

    def calculate_stat(self, ability: Ability):
        if self.data.overrideStats[ability].value:
            return self.data.overrideStats[ability].value
        return (
            self.data.stats[ability].value
            + (self.data.bonusStats[ability].value or 0)
            + sum(
                m.value
                for m in self.all_modifiers
                if m.value
                and m.type == "bonus"
                and m.subType == ability.name.lower() + "-score"
            )
        )

    def calculate_mod(self, ability: Ability):
        return math.floor((self.calculate_stat(ability) - 10) / 2)

    def find_trait_for(self, action: Action | ClassSpells | None) -> Trait | None:
        if isinstance(action, Action):
            for class_ in self.data.classes:
                for feature in class_.classFeatures:
                    if feature.definition.id == action.componentId:
                        return feature

    def find_class_for(
        self, action: Action | ClassSpells | None
    ) -> "DDBCharacter.Data.Class | None":
        if isinstance(action, Action):
            for class_ in self.data.classes:
                for feature in class_.classFeatures:
                    if feature.definition.id == action.componentId:
                        return class_
        if isinstance(action, ClassSpells):
            for class_ in self.data.classes:
                if class_.definition.id == action.characterClassId:
                    return class_

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

    def calculate_saving_throw(self, ability: Ability):
        self.accessed_applied_modifiers.add(f"{ability.name.lower()}-saving-throws")
        return self.calculate_mod(ability) + self.calculate_prof_modifier(
            f"{ability.name.lower()}-saving-throws"
        )

    def calculate_skill_mod(self, skill: str):
        return self.calculate_mod(skills[skill]) + self.calculate_prof_modifier(
            skill.replace(" ", "-")
        )

    def calculate_weapon_stats(self, weapon: Weapon) -> list[Ability]:
        properties_ = [p.name for p in weapon.definition.properties]
        if "Finesse" in properties_:
            return [Ability.STRENGTH, Ability.DEXTERITY]
        if "Thrown" in properties_:
            return [Ability.STRENGTH]
        if weapon.definition.longRange > 5 and "Reach" not in properties_:
            return [Ability.DEXTERITY]
        return [Ability.STRENGTH]

    def calculate_weapon_best_stat(self, weapon: Weapon) -> Ability:
        properties_ = [p.name for p in weapon.definition.properties]
        if "Finesse" in properties_:
            if self.calculate_stat(Ability.STRENGTH) > self.calculate_stat(
                Ability.DEXTERITY
            ):
                return Ability.STRENGTH
            return Ability.DEXTERITY
        if "Thrown" in properties_:
            return Ability.STRENGTH
        if weapon.definition.longRange > 5 and "Reach" not in properties_:
            return Ability.DEXTERITY
        return Ability.STRENGTH
        # https://github.com/MrPrimate/ddb-importer/blob/main/src/parser/item/weapon.js

    @property
    def grapple_dc(self) -> int:
        return 8 + self.calculate_mod(Ability.STRENGTH) + self.proficiency_modifier

    @property
    def speeds(self) -> list[tuple[str, int]]:
        s = self.data.race.weightSpeeds.normal
        return [
            (k, v)
            for k, v in (
                ("walk", s.walk),
                ("burrow", s.burrow),
                ("fly", s.fly),
                ("swim", s.swim),
                ("long jump", self.calculate_stat(Ability.STRENGTH)),
                ("hi jump", self.calculate_mod(Ability.STRENGTH) + 3),
            )
            if v
        ]

    def apply_template_variables(
        self,
        s: str,
        limited_use: LimitedUse | None,
        class_: "DDBCharacter.Data.Class | None",
        trait: Trait | None,
    ):
        template = re.compile(r"\{\{([^}]*)}}", re.DOTALL)
        pos = 0
        match = template.search(s, pos)
        while match:
            formula, signature = match[1], "unsigned"
            if "#" in formula:
                formula, signature = formula.split("#")
            stack = [lambda i: i]
            for token in parse_formula_tokens(formula):
                if not token:
                    continue
                if token == "(":
                    stack.append(lambda i: i)
                    continue
                elif token == ")":
                    r = stack.pop()
                    next_f = lambda l: l(r)
                elif token == "+":
                    next_f = lambda l: lambda r: l + r
                elif token == "*":
                    next_f = lambda l: lambda r: l * r
                else:
                    if token.isdigit():
                        next_f = lambda l: l(int(token))
                    elif token.startswith("modifier:"):
                        next_f = lambda l: l(
                            self.calculate_mod(
                                Ability.by_short_name(token.split(":")[-1])
                            )
                        )
                    elif token.startswith("savedc:"):
                        next_f = lambda l: l(
                            self.calculate_mod(
                                Ability.by_short_name(token.split(":")[-1])
                            )
                            + 8
                            + self.proficiency_modifier
                        )
                    elif token == "classlevel":
                        next_f = lambda l: l(class_.level)
                    elif token == "scalevalue":
                        next_f = lambda l: l(trait.scaler(class_.level))
                    elif token == "limiteduse":
                        next_f = lambda l: l(limited_use.max_uses(self))
                    elif token == "proficiency":
                        next_f = lambda l: l(self.proficiency_modifier)
                    else:
                        raise ValueError("Unrecognized token: {}".format(repr(token)))
                l = stack.pop()
                stack.append(next_f(l))
            value = stack.pop()

            if signature == "signed":
                result = f"{value:+}"
            else:
                result = str(value)
            insert = f"{result}"
            s = s[: match.start()] + insert + s[match.end() :]
            pos = match.start() + len(insert)
            match = template.search(s, pos)
        return s

    @cached_property
    def all_spells(self) -> list[tuple[Spell, ClassSpells | None]]:
        return [
            *((spell, None) for spell in self.data.spells.race),
            *((spell, None) for spell in self.data.spells.item or []),
            *((spell, None) for spell in self.data.spells.background or []),
            *((spell, None) for spell in self.data.spells.feat or []),
            *(
                (spell, class_spells)
                for class_spells in self.data.classSpells
                for spell in class_spells.spells
                if spell.activation.activationType == ActivationType.REACTION
            ),
        ]

    def filter_actions_by_activation(
        self, activation_type: "ActivationType"
    ) -> list[tuple[Action, None] | tuple[Spell, ClassSpells]]:
        return [
            *(
                (action, None)
                for action in self.data.actions.race or []
                if action.activation.activationType == activation_type
            ),
            *(
                (action, None)
                for action in self.data.actions.feat or []
                if action.activation.activationType == activation_type
            ),
            *(
                (action, None)
                for action in self.data.actions.item or []
                if action.activation.activationType == activation_type
            ),
            *(
                (action, None)
                for action in self.data.actions.background or []
                if action.activation.activationType == activation_type
            ),
            *(
                (action, None)
                for action in self.data.actions.class_ or []
                if action.activation.activationType == activation_type
            ),
            *(
                (spell, class_spells)
                for spell, class_spells in self.all_spells
                if spell.activation.activationType == activation_type
            ),
        ]

    @cached_property
    def reactions(
        self,
    ) -> list[tuple[Action, None] | tuple[Spell, ClassSpells]]:
        return self.filter_actions_by_activation(ActivationType.REACTION)

    @cached_property
    def special_actions(
        self,
    ) -> list[tuple[Action, None] | tuple[Spell, ClassSpells]]:
        return [
            *self.filter_actions_by_activation(ActivationType.RIDER),
            *self.filter_actions_by_activation(ActivationType.REST),
        ]

    @cached_property
    def all_options(self) -> list[Data.OptionSet.Option]:
        return [
            *(self.data.options.race or []),
            *(self.data.options.class_ or []),
            *(self.data.options.item or []),
            *(self.data.options.feat or []),
            *(self.data.options.background or []),
        ]

    @cached_property
    def actions(
        self,
    ) -> list[tuple[Action, None] | tuple[Spell, ClassSpells]]:
        return [
            *self.filter_actions_by_activation(ActivationType.BONUS_ACTION),
            *self.filter_actions_by_activation(ActivationType.ACTION),
            *self.filter_actions_by_activation(ActivationType.LONG_CAST),
        ]

    @cached_property
    def riders(
        self,
    ) -> list[tuple[Action, None] | tuple[Spell, ClassSpells]]:
        return self.filter_actions_by_activation(ActivationType.RIDER)

    @cached_property
    def accessed_applied_modifiers(self) -> set[str]:
        return set()

    def drain_applied_modifiers(self) -> set[str]:
        values = self.accessed_applied_modifiers.copy()
        self.accessed_applied_modifiers.clear()
        return values

    @cached_property
    def taken_actions(self) -> set[Action]:
        return set()

    @cached_property
    def taken_spells(self) -> set[tuple[Spell, ClassSpells | None]]:
        return set()

    @cached_property
    def taken_items(self) -> set[Item]:
        return set()

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
    def resistances(self):
        return [m.subType for m in self.all_modifiers if m.type == "resistance"]

    @cached_property
    def immunities(self):
        return [m.subType for m in self.all_modifiers if m.type == "immunity"]

    @cached_property
    def expertise(self):
        return [m.subType for m in self.all_modifiers if m.type == "expertise"]

    @cached_property
    def levels(self):
        return sum(c.level for c in self.data.classes)

    @cached_property
    def max_hp(self):
        if self.data.overrideHitPoints is not None:
            return self.data.overrideHitPoints
        return (
            self.data.baseHitPoints
            + (self.data.bonusHitPoints or 0)
            + (
                self.get_applied_modifier(
                    "hit-points-per-level", self.calculate_mod(Ability.CONSTITUTION)
                )
                * self.levels
            )
        )

    @cached_property
    def cur_hp(self):
        return self.max_hp - self.data.removedHitPoints

    @cached_property
    def temp_hp(self):
        return self.data.temporaryHitPoints

    @cached_property
    def armors(self) -> list[Armor]:
        return self.filter(self.data.inventory, Armor, lambda a: a.definition.id)

    @cached_property
    def shields(self) -> list[Shield]:
        return self.filter(self.data.inventory, Shield, lambda s: s.definition.id)

    @cached_property
    def weapons(self) -> list[Weapon]:
        return self.filter(self.data.inventory, Weapon, lambda w: w.definition.id)

    @cached_property
    def all_modifiers(self) -> list[Modifier]:
        return [
            *(self.data.modifiers.feat or []),
            *(self.data.modifiers.item or []),
            *(self.data.modifiers.race or []),
            *(self.data.modifiers.background or []),
            *(self.data.modifiers.class_ or []),
        ]

    def find_options_of_feature(
        self, name: str
    ) -> "list[DDBCharacter.Data.OptionSet.Option]":
        feature = self.find_class_feature(name)
        if feature is None:
            return []
        return [
            option
            for option in self.all_options
            if option.componentId == feature.definition.id
            or option.componentId
            in [i for gf in feature.definition.grantedFeats or [] for i in gf.featIds]
        ]

    def find_class_feature(self, name: str) -> Trait | None:
        for class_ in self.data.classes:
            for feature in class_.classFeatures:
                if feature.definition.name == name:
                    return feature
        return None

    @property
    def unarmed_stats(self) -> list[Ability]:
        if self.find_options_of_feature("Martial Arts"):
            return [Ability.STRENGTH, Ability.DEXTERITY]
        return [Ability.STRENGTH]

    @cached_property
    def unarmed_modifier(self) -> int:
        feature = self.find_class_feature("Martial Arts")
        if feature is not None:
            return max(
                self.calculate_mod(Ability.DEXTERITY),
                self.calculate_mod(Ability.STRENGTH),
            )
        return self.calculate_mod(Ability.STRENGTH)

    @cached_property
    def weapon_proficiencies(self) -> list[str]:
        return [
            p.split("-")[0].capitalize()
            for p in self.profencies
            if p.endswith("-weapons")
        ]

    @cached_property
    def weapon_masteries(self) -> list[str]:
        return [
            m.friendlySubtypeName
            for m in self.all_modifiers
            if m.type == "weapon-mastery"
        ]

    @cached_property
    def unarmed_damage(self) -> str:
        for class_ in self.data.classes:
            for feature in class_.classFeatures:
                if feature.definition.name == "Martial Arts":
                    return feature.scaler(class_.level) + f"{self.unarmed_modifier:+}"
        return "1"

    @cached_property
    def taken_modifiers(self) -> set[Modifier]:
        return set()

    def get_descriptive_modifiers(self, subtype: str) -> list[Modifier]:
        return [
            modifier
            for modifier in self.all_modifiers
            if modifier.subType == subtype and modifier.type not in ("set", "bonus")
        ]

    def get_leveraged_modifiers(self, subtype: str) -> list[LeverageModifier]:
        return [
            modifier
            for modifier in self.filter(self.all_modifiers, LeverageModifier)
            if modifier.subType == subtype
        ]

    def get_conditional_applied_modifiers(self, subtype: str) -> list[AppliedModifier]:
        return [
            m
            for m in self.filter(self.all_modifiers, AppliedModifier)
            if m.restriction and m.subType == subtype
        ]

    def get_applied_modifier_value(self, modifier: AppliedModifier) -> int:
        if modifier.value is not None:
            return modifier.value
        elif modifier.statId is not None:
            return self.calculate_mod(modifier.statId - 1)
        elif modifier.bonusTypes:
            value = 0
            for bt in modifier.bonusTypes:
                if bt == 1:
                    value += self.proficiency_modifier
                else:
                    raise ValueError("Unknown bonus type")
            return value
        else:
            raise ValueError("Unkonwn modifier value")

    def get_applied_modifier(self, subtype: str, base_value: int) -> int:
        for modifier in self.filter(self.all_modifiers, AppliedModifier):
            if modifier.subType != subtype:
                continue

            if modifier not in self.taken_modifiers:
                self.accessed_applied_modifiers.add(subtype)

            if modifier.restriction:
                continue

            value = self.get_applied_modifier_value(modifier)

            if modifier.type == "set":
                base_value = value
            elif modifier.type == "bonus":
                base_value += value
            else:
                raise ValueError("Unknown AppliedModifier type")

            self.taken_modifiers.add(modifier)
        return base_value

    @cached_property
    def immunities(self):
        return [m.subType for m in self.all_modifiers if m.type == "immunity"]

    @cached_property
    def resistances(self):
        return [m.subType for m in self.all_modifiers if m.type == "resistance"]

    def filter(
        self,
        inputs: list[BaseModel],
        t: type[_M],
        dedup: Callable[[_M], Any] = lambda i: i,
    ) -> list[_M]:
        result = []
        seen = set()
        for i in inputs:
            try:
                value = t.model_validate(i.model_dump())
                v = dedup(value)
                if v in seen:
                    continue
                seen.add(v)
                result.append(value)
            except ValidationError:
                continue
        return result


def load_character(character_id: int) -> DDBCharacter:
    res = requests.get(
        f"https://character-service.dndbeyond.com/character/v5/character/{character_id}"
    )
    res.raise_for_status()
    json_body = res.json()
    return DDBCharacter.model_validate(json_body)
