"""Tempered resistance progression audit.

The model converts conditional and damage-type-specific defenses into a
universal-equivalent contribution using conservative combat uptime.  It then
samples 20 completed perks from the active 48-perk pool and adds the expected
roguelike-card reserve through wave 50.  This is a balance regression tool,
not a replacement for in-game telemetry.
"""

from __future__ import annotations

import random


CAP = 0.80
ACTIVE_PERKS = 48
PURCHASED_PERKS = 20
RUNS = 20_000
CHECKPOINTS = (10, 20, 30, 40, 50)

# Mastered-perk universal-equivalent resistance after damage-type frequency,
# trigger uptime, mutual exclusivity, resource limits, and proc downtime.
EFFECTIVE_DR = {
    "Berserker": 0.09,
    "Demolitionist": 0.03,
    "FieldMedic": 0.08,
    "Firebug": 0.04,
    "Support": 0.04,
    "SWAT": 0.06,
    "Agony": 0.04,
    "Archangel": 0.07,
    "Artificer": 0.07,
    "Bulwark": 0.10,
    "Cinder": 0.04,
    "Daredevil": 0.07,
    "ForgeWarden": 0.04,
    "Hivemind": 0.04,
    "Medusa": 0.06,
    "Parasite": 0.08,
    "Predator": 0.09,
    "Riot": 0.10,
    "Shapeshifter": 0.10,
    "Symbiote": 0.02,
    "Venomancer": 0.07,
    "Warlord": 0.06,
    "Wendigo": 0.08,
    "Metronome": 0.03,
    "Hollow": 0.05,
    "Omen": 0.08,
    "TimeTraveler": 0.08,
}

# Remaining active perks are offensive/utility or grant armor rather than DR.
PERKS = list(EFFECTIVE_DR)
PERKS.extend(f"NonDefense{i}" for i in range(ACTIVE_PERKS - len(PERKS)))


def card_reserve(wave: int) -> float:
    """Expected accumulated resistance-card contribution by checkpoint."""
    return {10: 0.02, 20: 0.05, 30: 0.08, 40: 0.11, 50: 0.14}[wave]


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[round((len(ordered) - 1) * fraction)]


def main() -> None:
    rng = random.Random(0x5EED)
    samples = {wave: [] for wave in CHECKPOINTS}

    for _ in range(RUNS):
        route = rng.sample(PERKS, PURCHASED_PERKS)
        rng.shuffle(route)
        for wave in CHECKPOINTS:
            owned = round(PURCHASED_PERKS * wave / 50)
            raw = card_reserve(wave)
            raw += sum(EFFECTIVE_DR.get(name, 0.0) for name in route[:owned])
            samples[wave].append(min(raw, CAP))

    print(f"active perks={ACTIVE_PERKS}, purchased by wave 50={PURCHASED_PERKS}")
    print(f"global cap={CAP:.0%}, simulations={RUNS}")
    print("wave | p10 | median | p90 | capped")
    for wave in CHECKPOINTS:
        values = samples[wave]
        capped = sum(value >= CAP for value in values) / len(values)
        print(
            f"{wave:>4} | {percentile(values, 0.10):>4.0%} |"
            f" {percentile(values, 0.50):>6.0%} |"
            f" {percentile(values, 0.90):>4.0%} | {capped:>6.1%}"
        )

    total = sum(EFFECTIVE_DR.values()) + card_reserve(50)
    print(f"all defensive paths, condition-weighted uncapped total={total:.0%}")


if __name__ == "__main__":
    main()
