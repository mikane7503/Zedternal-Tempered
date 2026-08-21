#!/usr/bin/env python3
"""Synchronize displayed English/Korean numbers with Tempered config defaults.

This tool only edits upgrade description lines and UI bonus metadata.  It uses
the pre-Tempered seed assignments and the generated Tempered assignments in
each config class to derive old -> new numeric mappings.  Skill tier arrays are
scoped to their Standard/Deluxe description, which prevents cross-tier swaps.

The default mode is a dry run.  Pass --apply to write high-confidence changes.
Ambiguous substitutions are reported and deliberately left for manual review.
"""

from __future__ import annotations

import argparse
import math
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


BEGIN_MARKER = "BEGIN TEMPERED INI DEFAULTS"
END_MARKER = "END TEMPERED INI DEFAULTS"
ASSIGN_RE = re.compile(
    r"default\.([A-Za-z_]\w*(?:\[\d+\])?(?:\.[A-Za-z_]\w*)?)\s*=\s*"
    r"([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?f?)\s*;",
    re.IGNORECASE,
)
SOURCE_TARGET_RE = re.compile(
    r"(?i)(?:PerkBonus|WeaponBonus|EquipmentBonus|upgradeDescription)\s*(?:\(|=)"
)
LOC_TARGET_RE = re.compile(r"(?i)^\s*[A-Za-z_]*Description[A-Za-z_0-9]*\s*=")

# A few descriptions repeat the same old number for unrelated settings.  These
# ordered replacements document the intended meaning instead of guessing from
# the token alone.
ORDERED_OVERRIDES = {
    ("dkupgrade_skill_dealwiththedevil", 0, "80"): ("85", "30"),
}
PERK_ORDERED_OVERRIDES = {
    ("dkupgrade_perk_agony", 2, "30"): ("15", "10"),
    ("dkupgrade_perk_riot", 0, "2"): ("0.5", "0.75"),
}
TEXT_OVERRIDES = {
    ("dkupgrade_perk_cinder", 4): (
        ("10s</font> full immunity", "10s</font> of 50% damage reduction"),
        ("웨이브당 한 번 죽음을 회피하며", "불타는 적 한 명당 화염 피해량이 +4% 증가합니다. 웨이브당 한 번 죽음을 회피하며"),
        ("10초 동안 무적", "10초 동안 받는 피해가 50% 감소"),
    ),
    ("dkupgrade_perk_gambler", 1): (
        (">1 Dosh<", ">20 Dosh<"),
        ("1 도쉬", "20 도쉬"),
    ),
    ("dkupgrade_perk_hivemind", 3): (
        (">+50%<", ">+12.5%<"),
    ),
    ("dkupgrade_perk_hydra", 4): (
        ("Triple Damage", "1.1x Damage"),
        ("3배</font>", "1.1배</font>"),
    ),
}
GLOBAL_LOCALIZATION_REPLACEMENTS = {
    "new": (
        ("초당 0.25 HP", "초당 1 HP"),
        (" 증가합니다 (최대 <font color=\\\"#FFFFFF\\\">30%</font>).", " 증가합니다."),
        ("StandardSkillUpgradeDescription=\"대형 ZED를 처치하면 체력을 0 회복합니다.\"", "StandardSkillUpgradeDescription=\"대형 ZED를 처치하면 체력을 20 회복합니다.\""),
        ("DeluxeSkillUpgradeDescription=\"대형 ZED를 처치하면 체력을 0 회복합니다.\"", "DeluxeSkillUpgradeDescription=\"대형 ZED를 처치하면 체력을 40 회복합니다.\""),
        ("PerkUpgradeDescription1=\"<font color=\\\"#CC0000\\\">죽음의 정밀도:</font> <font color=\\\"#FF6666\\\">치명타 확률</font> <font color=\\\"#FFFFFF\\\">+%x%%</font>\"", "PerkUpgradeDescription1=\"<font color=\\\"#CC0000\\\">죽음의 정밀도:</font> <font color=\\\"#FFFFFF\\\">+%x%%</font> 확률로 <font color=\\\"#FF6666\\\">기본 피해 +100%</font>\""),
        ("StandardSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">40</font> 감소하지만, ZED를 처치할 때마다 <font color=\\\"#84d6d0\\\">이동 속도</font>가 <font color=\\\"#84d6d0\\\">15%</font> 증가합니다.\"", "StandardSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">40%</font> 감소하지만, <font color=\\\"#84d6d0\\\">이동 속도</font>가 <font color=\\\"#84d6d0\\\">10%</font> 증가합니다.\""),
        ("DeluxeSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">60</font> 감소하지만, ZED를 처치할 때마다 <font color=\\\"#84d6d0\\\">이동 속도</font>가 <font color=\\\"#84d6d0\\\">30%</font> 증가합니다.\"", "DeluxeSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">60%</font> 감소하지만, <font color=\\\"#84d6d0\\\">이동 속도</font>가 <font color=\\\"#84d6d0\\\">20%</font> 증가합니다.\""),
        ("DeluxeSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">5</font> 감소하는 대신, <font color=\\\"#42e087\\\">자신이 받는 모든 치유량</font>이 <font color=\\\"#84d6d0\\\">40%</font> 증가합니다.\"", "DeluxeSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">40%</font> 감소하는 대신, <font color=\\\"#42e087\\\">자신이 받는 모든 치유량</font>이 <font color=\\\"#84d6d0\\\">40%</font> 증가합니다.\""),
        ("StandardSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">25</font> 감소하는 대신, <font color=\\\"#42e087\\\">자신이 받는 모든 치유량</font>이 <font color=\\\"#84d6d0\\\">25%</font> 증가합니다.\"", "StandardSkillUpgradeDescription=\"<font color=\\\"#962ab9\\\">최대 체력</font>이 <font color=\\\"#cb1b43\\\">25%</font> 감소하는 대신, <font color=\\\"#42e087\\\">자신이 받는 모든 치유량</font>이 <font color=\\\"#84d6d0\\\">25%</font> 증가합니다.\""),
        ("ChainBody_Icicle=\"정밀 사격 충전 - 다음 사격 +500% 피해!\"", "ChainBody_Icicle=\"정밀 사격 충전 - 다음 사격 +200% 피해!\""),
        ("<font color=\\\"#FFFFFF\\\">2.5초마다</font> 흡수 효과를 전염시킵니다.", "<font color=\\\"#FFFFFF\\\">1.5초마다</font> 흡수 효과를 전염시킵니다."),
        ("StandardSkillUpgradeDescription=\"주변의 ZED에게 지속적으로 초당 3의 피해를 입히고 <font color=\\\"#8fce00\\\">독에 중독</font>시키는 <font color=\\\"#399c0e\\\">독성 오라</font>를 두릅니다.\"", "StandardSkillUpgradeDescription=\"주변 ZED에게 지속적으로 독을 적용하여 초당 최대 체력의 1.5% 피해를 입히는 <font color=\\\"#399c0e\\\">독성 오라</font>를 두릅니다. 대형 ZED와 보스에게는 효과가 감소합니다.\""),
        ("DeluxeSkillUpgradeDescription=\"주변의 ZED에게 지속적으로 초당 8의 피해를 입히고 <font color=\\\"#8fce00\\\">독에 중독</font>시키는 강력한 <font color=\\\"#b346ea\\\">독성 오라</font>를 두릅니다.\"", "DeluxeSkillUpgradeDescription=\"주변 ZED에게 지속적으로 독을 적용하여 초당 최대 체력의 3% 피해를 입히는 강력한 <font color=\\\"#b346ea\\\">독성 오라</font>를 두릅니다. 대형 ZED와 보스에게는 효과가 감소합니다.\""),
        ("DeluxeSkillUpgradeDescription=\"조준(아이언 사이트) 시 모든 무기의 <font color=\\\"#ff3399\\\">피해량</font>이 <font color=\\\"#66cc00\\\">40%</font> 증가합니다.\"", "DeluxeSkillUpgradeDescription=\"조준(아이언 사이트) 시 모든 무기의 <font color=\\\"#ff3399\\\">피해량</font>이 <font color=\\\"#66cc00\\\">30%</font> 증가합니다.\""),
        ("(7등급에서는 <font color=\\\"#FFFFFF\\\">350</font>킬", "(1등급에서는 <font color=\\\"#FFFFFF\\\">350</font>킬"),
        ("<font color=\\\"#FFFFFF\\\">100</font> 입힐 때마다 <font color=\\\"#FFD700\\\">뱀 비늘</font>", "<font color=\\\"#FFFFFF\\\">2500</font> 입힐 때마다 <font color=\\\"#FFD700\\\">뱀 비늘</font>"),
        ("<font color=\\\"#66cc00\\\">패트리아크</font>를 처치할 때마다 <font color=\\\"#ff3399\\\">추가 도쉬</font>를 얻습니다.", "<font color=\\\"#66cc00\\\">패트리아크</font>를 처치할 때마다 <font color=\\\"#ff3399\\\">200 도쉬</font>를 추가로 얻습니다."),
        ("<font color=\\\"#ff3399\\\">한스 볼터</font>를 처치할 때마다 <font color=\\\"#66cc00\\\">추가 도쉬</font>를 획득합니다.", "<font color=\\\"#ff3399\\\">한스 볼터</font>를 처치할 때마다 <font color=\\\"#66cc00\\\">200 도쉬</font>를 추가로 획득합니다."),
        ("제자리에 2초 동안 서 있으면 주변에 흡혈 오라를 생성합니다.", "제자리에 2초 동안 서 있으면 3미터 반경의 흡혈 오라를 생성합니다."),
        ("제자리에 2초 동안 서 있으면 주변에 강력한 흡혈 오라를 생성합니다.", "제자리에 2초 동안 서 있으면 4미터 반경의 강력한 흡혈 오라를 생성합니다."),
        ("<font color=\\\"#ebd402\\\">재사용 대기시간이 존재합니다.</font>", "<font color=\\\"#ebd402\\\">재사용 대기시간: 20초.</font>"),
    ),
}

REMOVED_LOCALIZATION_SECTIONS = {
    "dkupgrade_skill_primalroar",
    "dkupgrade_skill_fireproof",
    "dkupgrade_skill_shockwave",
    "dkupgrade_skill_timeburst",
    "dkupgrade_skill_outbreak",
    "dkupgrade_skill_toxicoverload",
    "dkupgrade_skill_reaper",
}

# Perk UI slots are not named after their config fields, so their relationship
# must be explicit.  None means that the displayed slot is intentionally
# unaffected by the changed INI values.
PERK_BONUS_PATHS = {
    "dkupgrade_perk_agony": ("movementperlevel", None, "headshotextensionchance"),
    "dkupgrade_perk_archangel": ("fieldmedicine", "combatreadiness", "healingtouch", "level10aurahealing", "level20miraclechance"),
    "dkupgrade_perk_artificer": ("damageperlevel", "reloadperlevel", "masterybonusperroll", "resonancecrossbonus"),
    "dkupgrade_perk_bulwark": ("damage", "health", "armor"),
    "dkupgrade_perk_cinder": ("firedamageperlevel", "burningtargetdamageperlevel", "damageperburningenemy", "permanentbonusperkills"),
    "dkupgrade_perk_cryophilite": ("basedamage", "headshotdamage", "reloadspeed", "iciclearrowbonus", None),
    "dkupgrade_perk_daredevil": ("damage", "damagehead", "penetration"),
    "dkupgrade_perk_forgewarden": ("fireexplosivedamage", "burndurationbonus", "level10damagebonus", None),
    "dkupgrade_perk_frost": ("chance", "damage", "freezeduration"),
    "dkupgrade_perk_gambler": ("doodle", "chance"),
    "dkupgrade_perk_hivemind": ("teamdamageperlevel", "teamreloadspeedperlevel", "neuralnetworkdamageperstage", "swarmdamagebonus"),
    "dkupgrade_perk_hollow": ("damageperlevel", "reloadperlevel"),
    "dkupgrade_perk_hydra": ("rateoffirebonus", "penetrationbonus", "magazinesizebonus", "twinstrikechance", "furymodedamagemult"),
    "dkupgrade_perk_maniac": ("grenadedamage", "reloadrate"),
    "dkupgrade_perk_medusa": ("headshotdamage", "reloadspeed", "spareammo", None, None, None),
    "dkupgrade_perk_metronome": ("assaultdamage", "assaultpenetration"),
    "dkupgrade_perk_omen": ("damage", "damageresist", "headshotdamage"),
    "dkupgrade_perk_parasite": ("lifestealperlevel", "healingreceivedperlevel", "damagepersiphonedenemy", None),
    "dkupgrade_perk_predator": ("damage",),
    "dkupgrade_perk_pyrokinetic": ("chance", "damage", "burnduration"),
    "dkupgrade_perk_reaper": ("critchance", "headshotdamage", "movementspeed", "level10damagebonus", None),
    "dkupgrade_perk_scavenger": ("reloadspeed", None, None, None, "level20damagebonus"),
    "dkupgrade_perk_specialagent": ("damage", "recoil", "reloadrate"),
    "dkupgrade_perk_symbiote": ("reloadspeed", None, None, "level10spareammobonus", "level20damagebonus"),
    "dkupgrade_perk_taskmaster": ("damage",),
    "dkupgrade_perk_tycoon": ("roundstipend", "bulkdiscount", None, None, "hostiletakeoverrate"),
    "dkupgrade_perk_venomancer": ("chance", "damage", "poisonduration"),
    "dkupgrade_perk_voodoo": (None, None, "damage"),
    "dkupgrade_perk_warlord": ("rifledamage", "headshotdamage", "reloadspeed", None, None, "ammocapacity", None),
    "dkupgrade_perk_wendigo": ("stalkdamagebonus", "movementspeed", "spareammobonus", "perfectambushbonus", "apexstalkerbonus"),
    "wmupgrade_perk_berserker": ("cfg_defense", "cfg_attackspeed", "cfg_damage"),
    "wmupgrade_perk_commando": (None, "cfg_reloadrate", "cfg_damage"),
    "wmupgrade_perk_demolitionist": ("cfg_grenadedamage", "cfg_lzdamage", "cfg_damage"),
    "wmupgrade_perk_fieldmedic": ("cfg_health", "cfg_healrate", "cfg_damage"),
    "wmupgrade_perk_firebug": ("cfg_defense", "cfg_ammo", "cfg_damage"),
    "wmupgrade_perk_gunslinger": ("cfg_movespeed", "cfg_switchspeed", "cfg_damage"),
    "wmupgrade_perk_sharpshooter": ("cfg_recoil", "cfg_damagehead", "cfg_damage"),
    "wmupgrade_perk_support": ("cfg_stoppingpower", "cfg_penetration", "cfg_damage"),
    "wmupgrade_perk_survivalist": (None, "cfg_spareammo", "cfg_damage"),
    "wmupgrade_perk_swat": ("cfg_armor", "cfg_magsize", "cfg_damage"),
}

PERK_DESCRIPTION_PATHS = {
    "dkupgrade_perk_agony": {2: ("level10movement", "level10damage", "headshotextensionchance"), 3: ("level20movement", "level20damage")},
    "dkupgrade_perk_archangel": {3: ("level10aurahealing",), 4: ("level20miraclechance",)},
    "dkupgrade_perk_artificer": {2: ("masterybonusperroll",), 3: ("resonancecrossbonus",), 4: ("reforgethreshold[0]", "reforgethreshold[8]")},
    "dkupgrade_perk_cinder": {2: ("burndurationperlevel",), 3: ("damageperburningenemy", "firespreadbonus", "burningenemyfireresist"), 4: ("level20damageperburningenemy", "permanentbonusperkills")},
    "dkupgrade_perk_cryophilite": {3: ("iciclearrowbonus",)},
    "dkupgrade_perk_forgewarden": {2: ("level10damagebonus",)},
    "dkupgrade_perk_hivemind": {2: ("teammovementpersymbiotestage",), 3: ("neuralnetworkdamageperstage", "neuralnetworkradius"), 4: ("swarmdamagebonus", "swarmreloadbonus", "swarmmovementbonus")},
    "dkupgrade_perk_hydra": {3: ("twinstrikechance",)},
    "dkupgrade_perk_metronome": {1: ("assaultdamage", "assaultpenetration"), 2: ("temporeload", "temporateoffire"), 3: ("momentumspeed", "momentumweaponswitch"), 4: ("bastiondamage",), 5: ("permanentbonusperstack",)},
    "dkupgrade_perk_parasite": {0: ("maxlifestealperhit",), 2: ("healingdamageratio",)},
    "dkupgrade_perk_predator": {0: ("damage",)},
    "dkupgrade_perk_reaper": {3: ("level10damagebonus",)},
    "dkupgrade_perk_riot": {0: ("meleedamageperlevel", "damageresistanceperlevel", "attackspeedperlevel"), 1: ("damagepernearbyenemy", "resistancepernearbyenemy"), 2: ("riotmovementspeedbonus", "riotattackspeedbonus")},
    "dkupgrade_perk_scavenger": {3: ("ammoscavengeamount",), 4: ("level20damagebonus",)},
    "dkupgrade_perk_symbiote": {6: ("level10spareammobonus", "level10stunbonus"), 7: ("level20damagebonus",)},
    "dkupgrade_perk_tycoon": {4: ("hostiletakeoverrate",)},
    "dkupgrade_perk_wendigo": {3: ("perfectambushbonus",), 4: ("apexstalkerbonus",)},
}


@dataclass(frozen=True)
class ValuePair:
    path: str
    old: float
    new: float
    tier: int | None


@dataclass
class OwnerMapping:
    owner: str
    category: str
    pairs: list[ValuePair]
    source_path: Path | None
    localization_kind: str | None


def decode_text(path: Path) -> tuple[str, str]:
    data = path.read_bytes()
    if data.startswith(b"\xff\xfe"):
        return data.decode("utf-16"), "utf-16"
    return data.decode("utf-8-sig"), "utf-8"


def encode_text(text: str, encoding: str) -> bytes:
    return text.encode(encoding)


def clean_number(value: float, decimals: int = 6) -> str:
    if abs(value - round(value)) < 1e-8:
        return str(int(round(value)))
    rendered = f"{value:.{decimals}f}".rstrip("0").rstrip(".")
    return "0" if rendered in {"-0", ""} else rendered


def display_number(value: float) -> str:
    if abs(value - round(value)) < 0.00005:
        return str(int(round(value)))
    return f"{value:.2f}".rstrip("0").rstrip(".")


def path_tier(path: str) -> int | None:
    match = re.search(r"\[(\d+)\]", path)
    return int(match.group(1)) if match else None


def extract_changed_pairs(text: str) -> list[ValuePair]:
    if BEGIN_MARKER not in text:
        return []
    begin = text.index(BEGIN_MARKER)
    end = text.index(END_MARKER, begin)
    old_values: dict[str, float] = {}
    for match in ASSIGN_RE.finditer(text[:begin]):
        old_values[match.group(1).lower()] = float(match.group(2).rstrip("fF"))
    new_values: dict[str, float] = {}
    for match in ASSIGN_RE.finditer(text[begin:end]):
        path = match.group(1).lower()
        if path.endswith(".length"):
            continue
        new_values[path] = float(match.group(2).rstrip("fF"))
    pairs: list[ValuePair] = []
    for path, new_value in new_values.items():
        if path not in old_values:
            continue
        old_value = old_values[path]
        if abs(old_value - new_value) < 1e-8:
            continue
        pairs.append(ValuePair(path, old_value, new_value, path_tier(path)))
    return pairs


def class_parent(text: str) -> str | None:
    match = re.search(
        r"(?im)^\s*class\s+[A-Za-z_]\w*\s+extends\s+([A-Za-z_]\w*)", text
    )
    return match.group(1) if match else None


def merge_owner(mapping: dict[str, OwnerMapping], item: OwnerMapping) -> None:
    key = item.owner.lower()
    if key not in mapping:
        mapping[key] = item
        return
    existing = mapping[key]
    known = {(pair.path, pair.old, pair.new) for pair in existing.pairs}
    existing.pairs.extend(
        pair for pair in item.pairs if (pair.path, pair.old, pair.new) not in known
    )


def collect_owner_mappings(project_root: Path) -> tuple[dict[str, OwnerMapping], list[str]]:
    new_source = project_root / "ZedternalRBPerkpackage" / "Classes"
    old_source = project_root / "Zedternal-Reborn-master" / "Classes"
    mappings: dict[str, OwnerMapping] = {}
    unavailable: list[str] = []
    for path in sorted(new_source.glob("*.uc")):
        text, _ = decode_text(path)
        pairs = extract_changed_pairs(text)
        if not pairs:
            continue
        name = path.stem
        parent = class_parent(text)
        if name.startswith("DKWrapper_"):
            if parent and parent.startswith("WM") and (old_source / f"{parent}.uc").exists():
                if name.startswith("DKWrapper_Skill_"):
                    wrapper_category = "wrapper_skill"
                elif name.startswith("DKWrapper_Perk_"):
                    wrapper_category = "wrapper_perk"
                else:
                    wrapper_category = "wrapper_equipment"
                merge_owner(
                    mappings,
                    OwnerMapping(
                        parent,
                        wrapper_category,
                        pairs,
                        old_source / f"{parent}.uc",
                        "original",
                    ),
                )
            else:
                unavailable.append(f"{name} -> {parent or 'unknown'}")
            continue
        if name.startswith("DKUpgrade_Skill_"):
            category = "skill"
        elif name.startswith("DKUpgrade_Perk_"):
            category = "perk"
        elif name.startswith(("DKUpgrade_Weapon_", "DKWeaponUpg_")):
            category = "weapon"
        else:
            category = "other"
        merge_owner(mappings, OwnerMapping(name, category, pairs, path, "new"))
    return mappings, unavailable


def line_tier(line: str, category: str) -> int | None:
    if category not in {"skill", "wrapper_skill"}:
        return None
    source_match = re.search(r"(?i)upgradeDescription\s*\(\s*([01])\s*\)", line)
    if source_match:
        return int(source_match.group(1))
    if re.match(r"(?i)^\s*StandardSkillUpgradeDescription\s*=", line):
        return 0
    if re.match(r"(?i)^\s*DeluxeSkillUpgradeDescription\s*=", line):
        return 1
    return None


def perk_line_paths(line: str, mapping: OwnerMapping, localization: bool = False) -> tuple[str, ...] | None:
    owner = mapping.owner.lower()
    bonus_match = re.search(r"(?i)PerkBonus\s*\(\s*(\d+)\s*\)", line)
    if bonus_match:
        slots = PERK_BONUS_PATHS.get(owner, ())
        index = int(bonus_match.group(1))
        if index >= len(slots) or slots[index] is None:
            return ()
        return (slots[index],)
    if localization:
        description_match = re.match(
            r"(?i)^\s*PerkUpgradeDescription(\d+)\s*=", line
        )
        index = int(description_match.group(1)) - 1 if description_match else None
    else:
        description_match = re.search(
            r"(?i)upgradeDescription\s*\(\s*(\d+)\s*\)", line
        )
        index = int(description_match.group(1)) if description_match else None
    if index is None:
        return None
    return PERK_DESCRIPTION_PATHS.get(owner, {}).get(index, ())


def restrict_mapping(mapping: OwnerMapping, paths: tuple[str, ...] | None) -> OwnerMapping:
    if paths is None:
        return mapping
    wanted = {path.lower() for path in paths}
    return OwnerMapping(
        mapping.owner,
        mapping.category,
        [pair for pair in mapping.pairs if pair.path.lower() in wanted],
        mapping.source_path,
        mapping.localization_kind,
    )


def transform_bonus_line(
    line: str, mapping: OwnerMapping
) -> tuple[str, list[tuple[str, str, str]], list[str]]:
    if not mapping.pairs:
        return line, [], []
    if len(mapping.pairs) != 1:
        return line, [], [f"PerkBonus expected one config path, found {len(mapping.pairs)}"]
    pair = mapping.pairs[0]
    raw_old, raw_new = pair.old, pair.new
    percent_old, percent_new = pair.old * 100.0, pair.new * 100.0
    changed: list[tuple[str, str, str]] = []

    def replace_field(match: re.Match[str]) -> str:
        value = float(match.group(2))
        if value <= 0:
            return match.group(0)
        if abs(value - raw_old) < 1e-6:
            new_value = raw_new
            kind = "bonus-field-raw"
        elif abs(value - percent_old) < 1e-6 or abs(value - round(percent_old)) < 1e-6:
            new_value = percent_new
            kind = "bonus-field-percent"
        elif abs(value - raw_new) < 1e-6:
            new_value = raw_new
            kind = "bonus-field-raw-normalized"
        elif abs(value - percent_new) < 1e-6:
            new_value = percent_new
            kind = "bonus-field-percent-normalized"
        else:
            return match.group(0)
        # UE3's PerkBonus fields are integers. Keep any positive fractional
        # percentage visible while preserving the exact value in descriptions.
        rendered = str(max(1, int(math.floor(new_value + 0.5))))
        if rendered == display_number(value):
            return match.group(0)
        changed.append((display_number(value), rendered, f"{pair.path}:{kind}"))
        return f"{match.group(1)}{rendered}"

    result = re.sub(
        r"(?i)(\b(?:baseValue|incValue|maxValue)\s*=\s*)([+-]?(?:\d+(?:\.\d*)?|\.\d+))",
        replace_field,
        line,
    )
    return result, changed, []


def representations(pair: ValuePair) -> list[tuple[str, str, str]]:
    if abs(pair.old) < 1e-12:
        return []
    values: list[tuple[str, str, str]] = []
    name = re.sub(r"\[\d+\]", "", pair.path).split(".")[-1].lower()
    raw_words = (
        "duration",
        "cooldown",
        "radius",
        "range",
        "dosh",
        "cost",
        "price",
        "threshold",
        "stacks",
        "count",
        "kills",
        "amount",
        "wave",
        "interval",
        "limit",
        "flat",
        "aurahealing",
    )
    percent_words = (
        "chance",
        "bonus",
        "resist",
        "reduction",
        "speed",
        "movement",
        "reload",
        "switch",
        "recoil",
        "penetration",
        "spread",
        "rate",
        "damage",
        "heal",
        "health",
        "armor",
        "capacity",
        "size",
        "share",
        "factor",
        "multiplier",
        "efficiency",
    )
    raw_semantic = any(word in name for word in raw_words)
    if "bonus" in name and not any(word in name for word in ("duration", "cooldown", "radius", "range")):
        raw_semantic = False
    percent_semantic = any(word in name for word in percent_words) and not raw_semantic
    allow_raw_percent = any(word in name for word in ("factor", "multiplier"))
    if raw_semantic or not percent_semantic or allow_raw_percent:
        values.append((clean_number(pair.old), clean_number(pair.new), "raw"))
    if percent_semantic and abs(pair.old) <= 10 and abs(pair.new) <= 10:
        values.append(
            (display_number(pair.old * 100.0), display_number(pair.new * 100.0), "percent")
        )
    if any(word in name for word in ("radius", "range")) and abs(pair.old) >= 100 and abs(pair.new) >= 100:
        values.append(
            (display_number(pair.old / 100.0), display_number(pair.new / 100.0), "meters")
        )
    unique: list[tuple[str, str, str]] = []
    seen: set[tuple[str, str]] = set()
    for old, new, kind in values:
        if old == new or (old, new) in seen:
            continue
        seen.add((old, new))
        unique.append((old, new, kind))
    return unique


def bonus_representations(pair: ValuePair) -> list[tuple[str, str, str]]:
    values = representations(pair)
    if abs(pair.old) <= 10 and abs(pair.new) <= 10:
        values.extend(
            [
                (clean_number(pair.old), clean_number(pair.new), "bonus-raw"),
                (
                    display_number(pair.old * 100.0),
                    display_number(pair.new * 100.0),
                    "bonus-percent",
                ),
            ]
        )
    unique: list[tuple[str, str, str]] = []
    seen: set[tuple[str, str]] = set()
    for old, new, kind in values:
        if old == new or (old, new) in seen:
            continue
        seen.add((old, new))
        unique.append((old, new, kind))
    return unique


def token_pattern(token: str) -> re.Pattern[str]:
    return re.compile(rf"(?<![A-Za-z0-9_.#]){re.escape(token)}(?![0-9.])")


def transform_target_line(
    line: str, mapping: OwnerMapping
) -> tuple[str, list[tuple[str, str, str]], list[str]]:
    tier = line_tier(line, mapping.category)
    description_index: int | None = None
    source_description = re.search(r"(?i)upgradeDescription\s*\(\s*(\d+)\s*\)", line)
    localized_description = re.match(r"(?i)^\s*PerkUpgradeDescription(\d+)\s*=", line)
    if source_description:
        description_index = int(source_description.group(1))
    elif localized_description:
        description_index = int(localized_description.group(1)) - 1
    is_bonus_line = bool(re.search(r"(?i)PerkBonus\s*\(", line))
    candidates: dict[str, set[tuple[str, str]]] = defaultdict(set)
    for pair in mapping.pairs:
        if tier is not None and pair.tier is not None and pair.tier != tier:
            continue
        pair_representations = bonus_representations(pair) if is_bonus_line else representations(pair)
        for old, new, kind in pair_representations:
            candidates[old].add((new, f"{pair.path}:{kind}"))
    changed: list[tuple[str, str, str]] = []
    ambiguous: list[str] = []
    prefix, separator, result = line.partition("=")
    if mapping.pairs:
        all_new_values_present = True
        for pair in mapping.pairs:
            new_tokens = [new for _, new, _ in representations(pair)]
            if new_tokens and not any(token_pattern(token).search(result) for token in new_tokens):
                all_new_values_present = False
                break
        text_rules = TEXT_OVERRIDES.get((mapping.owner.lower(), description_index), ())
        if all_new_values_present and all(
            new_text in result or old_text not in result for old_text, new_text in text_rules
        ):
            return line, [], []
    ordered_rules = list(ORDERED_OVERRIDES.items()) + list(PERK_ORDERED_OVERRIDES.items())
    for (owner, override_index, old), replacements in ordered_rules:
        actual_index = description_index if owner.startswith("dkupgrade_perk_") else tier
        if mapping.owner.lower() != owner or actual_index != override_index:
            continue
        pattern = token_pattern(old)
        replacement_iter = iter(replacements)
        replacement_count = 0

        def replace_ordered(match: re.Match[str]) -> str:
            nonlocal replacement_count
            try:
                replacement = next(replacement_iter)
            except StopIteration:
                return match.group(0)
            replacement_count += 1
            changed.append((old, replacement, "ordered-override"))
            return replacement

        result = pattern.sub(replace_ordered, result)
        if replacement_count not in {0, len(replacements)}:
            ambiguous.append(
                f"ordered override {old}: expected {len(replacements)} occurrences, "
                f"found {replacement_count}"
            )
    placeholders: list[tuple[str, str]] = []
    for old in sorted(candidates, key=lambda item: (-len(item), item)):
        pattern = token_pattern(old)
        if not pattern.search(result):
            continue
        new_values = {item[0] for item in candidates[old]}
        if len(new_values) != 1:
            ambiguous.append(f"{old} -> {sorted(new_values)}")
            continue
        new_value = next(iter(new_values))
        placeholder = f"@@TEMPERED_DISPLAY_{len(placeholders)}@@"
        updated, count = pattern.subn(placeholder, result)
        if count:
            reason = ",".join(sorted(item[1] for item in candidates[old] if item[0] == new_value))
            changed.append((old, new_value, reason))
            placeholders.append((placeholder, new_value))
            result = updated
    for placeholder, new_value in placeholders:
        result = result.replace(placeholder, new_value)
    if description_index is not None:
        for old_text, new_text in TEXT_OVERRIDES.get(
            (mapping.owner.lower(), description_index), ()
        ):
            if old_text in result and new_text not in result:
                result = result.replace(old_text, new_text)
                changed.append((old_text, new_text, "text-override"))
    return prefix + separator + result, changed, ambiguous


def transform_source(path: Path, mapping: OwnerMapping) -> tuple[bytes, list[str], list[str]]:
    text, encoding = decode_text(path)
    output: list[str] = []
    changes: list[str] = []
    ambiguous: list[str] = []
    description_counter = 0
    for number, line in enumerate(text.splitlines(keepends=True), start=1):
        if mapping.category in {"skill", "perk"} and re.search(
            r"(?i)^\s*upgradeDescription\s*\(", line
        ):
            repaired = re.sub(
                r"(?i)(upgradeDescription\s*\(\s*)[^)]*(\s*\))",
                rf"\g<1>{description_counter}\g<2>",
                line,
                count=1,
            )
            if repaired != line:
                changes.append(
                    f"{path.name}:{number}: repaired description slot -> {description_counter}"
                )
                line = repaired
            description_counter += 1
        if SOURCE_TARGET_RE.search(line):
            active_mapping = mapping
            if mapping.category in {"perk", "wrapper_perk", "wrapper_equipment"}:
                active_mapping = restrict_mapping(mapping, perk_line_paths(line, mapping))
            if re.search(r"(?i)PerkBonus\s*\(", line):
                updated, line_changes, line_ambiguous = transform_bonus_line(line, active_mapping)
            else:
                updated, line_changes, line_ambiguous = transform_target_line(line, active_mapping)
            if line_changes:
                changes.append(
                    f"{path.name}:{number}: "
                    + "; ".join(f"{old}->{new} ({why})" for old, new, why in line_changes)
                )
            ambiguous.extend(f"{path.name}:{number}: {item}" for item in line_ambiguous)
            line = updated
        output.append(line)
    return encode_text("".join(output), encoding), changes, ambiguous


def section_ranges(lines: list[str]) -> dict[str, tuple[int, int]]:
    starts: list[tuple[str, int]] = []
    for index, line in enumerate(lines):
        match = re.match(r"^\s*\[([^\]]+)\]\s*$", line)
        if match:
            starts.append((match.group(1).lower(), index))
    ranges: dict[str, tuple[int, int]] = {}
    for position, (name, start) in enumerate(starts):
        end = starts[position + 1][1] if position + 1 < len(starts) else len(lines)
        ranges[name] = (start, end)
    return ranges


def transform_localization(
    path: Path, mappings: dict[str, OwnerMapping], kind: str
) -> tuple[bytes, list[str], list[str]]:
    text, encoding = decode_text(path)
    lines = text.splitlines(keepends=True)
    ranges = section_ranges(lines)
    changes: list[str] = []
    ambiguous: list[str] = []
    if kind == "new":
        removed_ranges = [
            (name, *ranges[name])
            for name in REMOVED_LOCALIZATION_SECTIONS
            if name in ranges
        ]
        for name, start, end in sorted(removed_ranges, key=lambda item: item[1], reverse=True):
            del lines[start:end]
            changes.append(f"removed localization section [{name}]")
        ranges = section_ranges(lines)
    for owner_key, mapping in mappings.items():
        if mapping.localization_kind != kind or owner_key not in ranges:
            continue
        start, end = ranges[owner_key]
        for index in range(start + 1, end):
            if not LOC_TARGET_RE.match(lines[index]):
                continue
            active_mapping = mapping
            if mapping.category in {"perk", "wrapper_perk", "wrapper_equipment"}:
                active_mapping = restrict_mapping(
                    mapping, perk_line_paths(lines[index], mapping, localization=True)
                )
            updated, line_changes, line_ambiguous = transform_target_line(lines[index], active_mapping)
            if line_changes:
                changes.append(
                    f"[{mapping.owner}] line {index + 1}: "
                    + "; ".join(f"{old}->{new} ({why})" for old, new, why in line_changes)
                )
            ambiguous.extend(
                f"[{mapping.owner}] line {index + 1}: {item}" for item in line_ambiguous
            )
            lines[index] = updated
    joined = "".join(lines)
    for old_text, new_text in GLOBAL_LOCALIZATION_REPLACEMENTS.get(kind, ()):
        if old_text in joined:
            joined = joined.replace(old_text, new_text)
            changes.append(f"global: {old_text}->{new_text}")
    return encode_text(joined, encoding), changes, ambiguous


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--show", type=int, default=80, help="number of change lines to print")
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[2]
    mappings, unavailable = collect_owner_mappings(project_root)
    writes: list[tuple[Path, bytes]] = []
    changes: list[str] = []
    ambiguous: list[str] = []

    automatic_categories = {
        "skill",
        "wrapper_skill",
        "weapon",
        "perk",
        "wrapper_perk",
        "wrapper_equipment",
    }
    automatic_mappings = {
        key: value for key, value in mappings.items() if value.category in automatic_categories
    }

    for mapping in automatic_mappings.values():
        if mapping.source_path is None:
            continue
        updated, item_changes, item_ambiguous = transform_source(mapping.source_path, mapping)
        if updated != mapping.source_path.read_bytes():
            writes.append((mapping.source_path, updated))
        changes.extend(item_changes)
        ambiguous.extend(item_ambiguous)

    localization_jobs = [
        (
            project_root / "ZedternalRBPerkpackage" / "Localization" / "KOR" / "ZedternalRBPerkpackage.kor",
            "new",
        ),
        (
            project_root / "Zedternal-Reborn-master" / "Localization" / "INT" / "ZedternalReborn.int",
            "original",
        ),
        (
            project_root / "ZedternalRBPerkpackage" / "Localization" / "KOR" / "ZedternalReborn.kor",
            "original",
        ),
    ]
    for path, kind in localization_jobs:
        updated, item_changes, item_ambiguous = transform_localization(
            path, automatic_mappings, kind
        )
        if updated != path.read_bytes():
            writes.append((path, updated))
        changes.extend(f"{path.name}: {item}" for item in item_changes)
        ambiguous.extend(f"{path.name}: {item}" for item in item_ambiguous)

    if args.apply:
        for path, data in writes:
            path.write_bytes(data)

    print(f"Mode: {'APPLY' if args.apply else 'DRY RUN'}")
    print(f"Display owners with changed config values: {len(mappings)}")
    print(f"High-confidence automatic owners: {len(automatic_mappings)}")
    print(f"Files changed: {len(writes)}")
    print(f"Numeric substitutions: {len(changes)}")
    print(f"Ambiguous candidates left unchanged: {len(ambiguous)}")
    if changes and args.show:
        print("\nChanges:")
        for item in changes[: args.show]:
            print(f"  {item}")
        if len(changes) > args.show:
            print(f"  ... {len(changes) - args.show} more")
    if ambiguous and args.show:
        print("\nAmbiguous candidates:")
        for item in ambiguous[: args.show]:
            print(f"  {item}")
        if len(ambiguous) > args.show:
            print(f"  ... {len(ambiguous) - args.show} more")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
