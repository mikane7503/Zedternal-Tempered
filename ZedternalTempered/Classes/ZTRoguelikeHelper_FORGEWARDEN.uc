/** "Slag Cascade" - Fire/explosive kills 25% chance explode for 50% max HP. */
class ZTRoguelikeHelper_FORGEWARDEN extends ZTRoguelikeHelper;

const PROC_CHANCE = 0.25;
const FIRE_BONUS = 0.15;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Explosive')))
        return FIRE_BONUS;
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (FRand() <= PROC_CHANCE)
        `log("[DK_RL_FORGEWARDEN] Slag Cascade: explosion!");
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_FORGEWARDEN"
}
