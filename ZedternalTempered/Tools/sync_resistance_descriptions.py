"""Synchronize the hand-written resistance descriptions changed by Tempered."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLASSES = ROOT / "Classes"
KOR = ROOT / "Localization" / "KOR" / "ZedternalRBPerkpackage.kor"
ZR_KOR = ROOT / "Localization" / "KOR" / "ZedternalReborn.kor"


CUSTOM = {
    "DKUpgrade_Perk_Cinder": [("10s</font> of 50% damage reduction", "10s</font> of 25% damage reduction")],
    "DKUpgrade_Perk_Metronome": [("15%</font> Damage Resistance", "10%</font> Damage Resistance")],
    "DKUpgrade_Perk_Riot": [
        ("+0.5%</font> <font color=\"#FFB347\">Damage Resistance", "+0.4%</font> <font color=\"#FFB347\">Damage Resistance"),
        ("+2.5%</font> Damage Resistance", "+1%</font> Damage Resistance"),
        ("cap <font color=\"#FFFFFF\">2.5</font> enemies", "cap <font color=\"#FFFFFF\">5</font> enemies"),
    ],
    "DKUpgrade_Skill_AshenBulwark": [("21.67%", "20%")],
    "DKUpgrade_Skill_Aware": [("15%", "10%"), ("30%", "20%")],
    "DKUpgrade_Skill_BatteringRam": [("+10% Damage Resistance", "+8% Damage Resistance"), ("+20% Damage Resistance", "+16% Damage Resistance")],
    "DKUpgrade_Skill_BloodBank": [("30%", "20%"), ("40%", "30%")],
    "DKUpgrade_Skill_BloodShield": [("6%</font> damage resistance per siphon", "1.5%</font> damage resistance per siphon"), ("10%</font> damage resistance per siphon", "2.5%</font> damage resistance per siphon")],
    "DKUpgrade_Skill_BugFixing": [("15%", "10%"), ("30%", "20%")],
    "DKUpgrade_Skill_ChronoCarapace": [("30%", "20%"), ("50%", "35%"), ("15%", "12%")],
    "DKUpgrade_Skill_CloseCall": [("6.67%", "8%"), ("13.33%", "16%")],
    "DKUpgrade_Skill_Deflector": [("15%", "12%"), ("30%", "24%")],
    "DKUpgrade_Skill_EmpathicLink": [("8.33%", "10%")],
    "DKUpgrade_Skill_FLAK": [("15%", "12%"), ("30%", "24%")],
    "DKUpgrade_Skill_Fencer": [("25%", "10%"), ("40%", "20%")],
    "DKUpgrade_Skill_FrozenHide": [("15%", "10%"), ("25%", "20%")],
    "DKUpgrade_Skill_HoldTheLine": [("10%", "8%"), ("20%", "16%")],
    "DKUpgrade_Skill_HolyResilience": [("3.33%", "5%"), ("8.33%", "10%")],
    "DKUpgrade_Skill_ImpenetrableSkin": [("3.33%", "5%"), ("6.67%", "10%")],
    "DKUpgrade_Skill_Indifferent": [("25%", "15%"), ("50%", "30%")],
    "DKUpgrade_Skill_MartyrBlessing": [("grants <font color=\"#eeeeff\">10%</font> damage resistance per heal", "grants <font color=\"#eeeeff\">8%</font> damage resistance per heal")],
    "DKUpgrade_Skill_NoiseCancelling": [("10%", "12%"), ("20%", "24%")],
    "DKUpgrade_Skill_PrimordialVigor": [("1.5%", "0.6%"), ("2.5%", "1.2%")],
    "DKUpgrade_Skill_ShedSkin": [("6.67%", "8%"), ("13.33%", "16%")],
    "DKUpgrade_Skill_SlagArmor": [("15%", "12%"), ("35%", "24%")],
    "DKUpgrade_Skill_SteelSkin": [("10%", "15%"), ("20%", "25%")],
    "DKUpgrade_Skill_Stoic": [("10%", "15%"), ("20%", "30%")],
    "DKUpgrade_Skill_ThickSkin": [("15%", "10%"), ("30%", "20%")],
    "DKUpgrade_Skill_TrophyShield": [("10%", "8%"), ("15%", "16%")],
    "DKUpgrade_Skill_Venomweave": [("5% damage reduction", "3% damage reduction"), ("7% damage reduction", "5% damage reduction"), ("Max 50%", "Max 30%")],
}

ORIGINAL = {
    "WMUpgrade_Skill_Brawler": [("25%", "20%")],
    "WMUpgrade_Skill_CoagulantBooster": [("0.10%", "0.125%"), ("6.67%", "5%"), ("0.4%", "0.333%"), ("11.67%", "10%")],
    "WMUpgrade_Skill_FocusInjection": [("10%</font> 증가시킵니다", "8%</font> 증가시킵니다"), ("최대 20% 누적", "최대 15% 누적"), ("50%</font> 누적", "30%</font> 누적")],
    "WMUpgrade_Skill_FrontLine": [("11.67%", "10%"), ("1.67%", "2%"), ("25%", "20%"), ("3.33%", "4%")],
    "WMUpgrade_Skill_MadBomber": [("75%", "20%")],
    "WMUpgrade_Skill_Parry": [("피해 저항 10%", "피해 저항 8%"), ("13.33%", "16%")],
    "WMUpgrade_Skill_Resistance": [("8.33%", "10%")],
    "WMUpgrade_Skill_RiotShield": [("35%", "25%"), ("60%", "40%")],
    "WMUpgrade_Skill_SonicResistantRounds": [("30%", "25%"), ("60%", "40%")],
    "WMUpgrade_Skill_Tank": [("6.67%", "5%")],
}

CUSTOM_KOR = {
    "DKUpgrade_Perk_Cinder": [("10초 동안 피해를 50% 감소", "10초 동안 피해를 25% 감소")],
    "DKUpgrade_Perk_Metronome": [("피해 저항 <font color=\"#FFFFFF\">15%</font>", "피해 저항 <font color=\"#FFFFFF\">10%</font>")],
    "DKUpgrade_Perk_Riot": [("피해 저항</font> <font color=\"#FFFFFF\">+0.5%</font>", "피해 저항</font> <font color=\"#FFFFFF\">+0.4%</font>"), ("피해 저항이 2.5% 증가합니다 (최대 2.5명)", "피해 저항이 1% 증가합니다 (최대 5명)")],
    "DKUpgrade_Perk_Predator": [("피해 저항 +25%%", "피해 저항 +10%%"), ("저항 +30%%", "저항 +15%%"), ("저항 +50%%", "저항 +25%%"), ("받는 피해 -1%%", "받는 피해 -0.5%%")],
    "DKUpgrade_Perk_TimeTraveler": [("무기의 <font color=\"#15d7fa\">모든 능력치</font>가 <font color=\"#77d914\">%x%%</font> 증가합니다.", "무기 능력치는 등급당 <font color=\"#77d914\">1%</font>, 피해 저항은 등급당 <font color=\"#77d914\">0.4%</font> 증가합니다.")],
    "DKUpgrade_Skill_BatteringRam": [("피해 저항이 10% 증가", "피해 저항이 8% 증가"), ("피해 저항이 20% 증가", "피해 저항이 16% 증가")],
    "DKUpgrade_Skill_BloodShield": [("스택당 <font color=\"#FFFFFF\">6%</font>의 피해 저항", "스택당 <font color=\"#FFFFFF\">1.5%</font>의 피해 저항"), ("스택당 <font color=\"#FFFFFF\">10%</font>의 피해 저항", "스택당 <font color=\"#FFFFFF\">2.5%</font>의 피해 저항")],
    "DKUpgrade_Skill_MartyrBlessing": [("치유할 때마다 <font color=\"#eeeeff\">10%</font>의 피해 저항력", "치유할 때마다 <font color=\"#eeeeff\">8%</font>의 피해 저항력")],
    "DKUpgrade_Skill_Venomweave": [("5%의 피해 감소", "3%의 피해 감소"), ("7%의 피해 감소", "5%의 피해 감소"), ("최대 50%", "최대 30%")],
    "DKUpgrade_Skill_NoSurrender": [("체력이 <font color=\"#DC143C\">5% 미만</font>일 때 <font color=\"#4169E1\">피해 저항이 15% 증가</font>하며, 이 상태에서 근접 공격으로 적을 처치하면 <font color=\"#32CD32\">체력을 25 회복</font>", "체력이 <font color=\"#DC143C\">10% 미만</font>일 때 <font color=\"#4169E1\">피해 저항이 10% 증가</font>하며, 이 상태에서 근접 공격으로 적을 처치하면 <font color=\"#32CD32\">체력을 15 회복</font>"), ("체력이 <font color=\"#DC143C\">10% 미만</font>일 때 <font color=\"#4169E1\">피해 저항이 20% 증가</font>하며, 이 상태에서 근접 공격으로 적을 처치하면 <font color=\"#32CD32\">체력을 40 회복</font>", "체력이 <font color=\"#DC143C\">15% 미만</font>일 때 <font color=\"#4169E1\">피해 저항이 20% 증가</font>하며, 이 상태에서 근접 공격으로 적을 처치하면 <font color=\"#32CD32\">체력을 20 회복</font>")],
    "DKUpgrade_Skill_ToxicImmunity": [("<font color=\"#00FF00\">독 피해 저항력</font>을 <font color=\"#FFFFFF\">8.33%</font> 얻습니다.", "<font color=\"#00FF00\">독 피해 저항력</font>을 <font color=\"#FFFFFF\">15%</font> 얻습니다."), ("<font color=\"#FFD700\">독에 완전히 면역</font>되며, <font color=\"#00FF00\">독 피해를 받을 때 오히려 체력을 회복</font>합니다.", "<font color=\"#00FF00\">독 피해 저항력</font>을 <font color=\"#FFFFFF\">30%</font> 얻습니다.")],
    "DKUpgrade_Skill_ToxicAbsorption": [("<font color=\"#399c0e\">독성 피해에 완전히 면역</font>이 됩니다. 흡수한 독 피해의 <font color=\"#399c0e\">50%</font>만큼을", "독성 피해가 <font color=\"#399c0e\">30%</font> 감소하며, 막은 피해의 <font color=\"#399c0e\">50%</font>만큼을"), ("<font color=\"#b346ea\">독성 피해에 완전히 면역</font>이 됩니다. 흡수한 독 피해의 <font color=\"#b346ea\">100%</font>만큼을", "독성 피해가 <font color=\"#b346ea\">50%</font> 감소하며, 막은 피해의 <font color=\"#b346ea\">100%</font>만큼을")],
    "DKUpgrade_Skill_SafetyFirst": [("50%</font> 감소합니다.", "30%</font> 감소합니다."), ("100%</font> 감소합니다(완전 면역).", "50%</font> 감소합니다.")],
}

KOR_FIELDS = {
    "DKUpgrade_Perk_Metronome": {
        "PerkUpgradeDescription5": "<font color=\"#ffaa22\">BASTION</font>: 레벨당 근접 피해량 <font color=\"#FFFFFF\">+1%</font>, 처치 시 <font color=\"#FFFFFF\">1 HP 회복</font>, 피해 저항 <font color=\"#FFFFFF\">10%</font>. 동기화 조건: <font color=\"#FFFFFF\">근거리 처치</font> (5m 미만).",
    },
    "DKUpgrade_Perk_Riot": {
        "PerkUpgradeDescription1": "<font color=\"#FF4500\">브롤러즈 엣지:</font> 레벨당 근접 공격력 +1.25%, 피해 저항 +0.4%, 공격 속도 +0.75%",
        "PerkUpgradeDescription2": "<font color=\"#8B0000\">레벨 10:</font> 2.5m 이내의 적 하나당 근접 공격력 +1%, 피해 저항 +1% (최대 5명).",
    },
    "DKUpgrade_Perk_TimeTraveler": {
        "PerkUpgradeDescription1": "무기 능력치는 등급당 <font color=\"#77d914\">1%</font>, 피해 저항은 등급당 <font color=\"#77d914\">0.4%</font> 증가합니다.",
    },
    "DKUpgrade_Skill_BatteringRam": {
        "StandardSkillUpgradeDescription": "질주 중 피해 저항이 <font color=\"#4169E1\">8%</font> 증가하며, 질주 종료 직후 첫 근접 공격이 강화됩니다.",
        "DeluxeSkillUpgradeDescription": "질주 중 피해 저항이 <font color=\"#4169E1\">16%</font> 증가하며, 질주 종료 직후 첫 근접 공격이 더욱 강화됩니다.",
    },
    "DKUpgrade_Skill_BloodShield": {
        "StandardSkillUpgradeDescription": "체력 30% 미만에서 사이펀을 소모해 스택당 <font color=\"#FFFFFF\">1.5%</font>, 최대 <font color=\"#FFFFFF\">30%</font> 피해 저항을 6초간 얻습니다.",
        "DeluxeSkillUpgradeDescription": "체력 30% 미만에서 사이펀을 소모해 스택당 <font color=\"#FFFFFF\">2.5%</font>, 최대 <font color=\"#FFFFFF\">30%</font> 피해 저항을 10초간 얻습니다.",
    },
    "DKUpgrade_Skill_MartyrBlessing": {
        "StandardSkillUpgradeDescription": "아군 치유마다 피해 저항 <font color=\"#eeeeff\">5%</font>, 최대 <font color=\"#eeeeff\">10%</font>.",
        "DeluxeSkillUpgradeDescription": "아군 치유마다 피해 저항 <font color=\"#eeeeff\">8%</font>, 최대 <font color=\"#eeeeff\">20%</font>.",
    },
    "DKUpgrade_Skill_Venomweave": {
        "StandardSkillUpgradeDescription": "주변의 중독된 ZED 한 마리당 피해 감소 <font color=\"#399c0e\">3%</font>, 최대 30%.",
        "DeluxeSkillUpgradeDescription": "주변의 중독된 ZED 한 마리당 피해 감소 <font color=\"#b346ea\">5%</font>, 최대 30%.",
    },
    "DKUpgrade_Skill_NoSurrender": {
        "StandardSkillUpgradeDescription": "체력 10% 미만에서 피해 저항 10%, 근접 처치 시 15 HP 회복.",
        "DeluxeSkillUpgradeDescription": "체력 15% 미만에서 피해 저항 20%, 근접 처치 시 20 HP 회복.",
    },
    "DKUpgrade_Skill_ToxicImmunity": {
        "StandardSkillUpgradeDescription": "독 피해 저항을 <font color=\"#00FF00\">15%</font> 얻습니다.",
        "DeluxeSkillUpgradeDescription": "독 피해 저항을 <font color=\"#00FF00\">30%</font> 얻습니다.",
    },
    "DKUpgrade_Skill_ToxicAbsorption": {
        "StandardSkillUpgradeDescription": "독 피해를 <font color=\"#399c0e\">30%</font> 막고, 막은 피해의 50%만큼 회복합니다.",
        "DeluxeSkillUpgradeDescription": "독 피해를 <font color=\"#b346ea\">50%</font> 막고, 막은 피해의 100%만큼 회복합니다.",
    },
    "DKUpgrade_Skill_SafetyFirst": {
        "StandardSkillUpgradeDescription": "플레이어가 가한 폭발 피해를 <font color=\"#66cc00\">30%</font> 감소시킵니다.",
        "DeluxeSkillUpgradeDescription": "플레이어가 가한 폭발 피해를 <font color=\"#66cc00\">50%</font> 감소시킵니다.",
    },
}


def decode_text(raw: bytes) -> tuple[str, str]:
    if raw.startswith(b"\xff\xfe"):
        return raw[2:].decode("utf-16-le"), "utf-16-le"
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw[3:].decode("utf-8"), "utf-8-sig"
    return raw.decode("utf-8"), "utf-8"


def encode_text(text: str, encoding: str) -> bytes:
    if encoding == "utf-16-le":
        return b"\xff\xfe" + text.encode("utf-16-le")
    if encoding == "utf-8-sig":
        return b"\xef\xbb\xbf" + text.encode("utf-8")
    return text.encode("utf-8")


def replace_file(path: Path, pairs: list[tuple[str, str]]) -> int:
    if not path.exists():
        return 0
    raw = path.read_bytes()
    text, encoding = decode_text(raw)
    count = 0
    for old, new in pairs:
        hits = text.count(old)
        text = text.replace(old, new)
        count += hits
    path.write_bytes(encode_text(text, encoding))
    return count


def replace_section(path: Path, section: str, pairs: list[tuple[str, str]]) -> int:
    raw = path.read_bytes()
    text, encoding = decode_text(raw)
    marker = f"[{section}]"
    start = text.find(marker)
    if start < 0:
        return 0
    end = text.find("\n[", start + len(marker))
    if end < 0:
        end = len(text)
    block = text[start:end]
    count = 0
    for old, new in pairs:
        hits = block.count(old)
        block = block.replace(old, new)
        count += hits
    text = text[:start] + block + text[end:]
    path.write_bytes(encode_text(text, encoding))
    return count


def set_section_fields(path: Path, section: str, fields: dict[str, str]) -> int:
    raw = path.read_bytes()
    text, encoding = decode_text(raw)
    marker = f"[{section}]"
    start = text.find(marker)
    if start < 0:
        return 0
    end = text.find("\n[", start + len(marker))
    if end < 0:
        end = len(text)
    block = text[start:end]
    changed = 0
    lines = block.splitlines()
    for index, line in enumerate(lines):
        for key, value in fields.items():
            if line.startswith(key + "="):
                replacement = f'{key}="{value}"'
                if line != replacement:
                    lines[index] = replacement
                    changed += 1
    text = text[:start] + "\n".join(lines) + text[end:]
    path.write_bytes(encode_text(text, encoding))
    return changed


def main() -> None:
    changed = 0
    for owner, pairs in CUSTOM.items():
        changed += replace_file(CLASSES / f"{owner}.uc", pairs)
        changed += replace_section(KOR, owner, pairs)
    for owner, pairs in ORIGINAL.items():
        changed += replace_section(ZR_KOR, owner, pairs)
    for owner, pairs in CUSTOM_KOR.items():
        if owner not in KOR_FIELDS and owner != "DKUpgrade_Perk_Predator":
            changed += replace_section(KOR, owner, pairs)
    for owner, fields in KOR_FIELDS.items():
        changed += set_section_fields(KOR, owner, fields)
    print(f"resistance description substitutions={changed}")


if __name__ == "__main__":
    main()
