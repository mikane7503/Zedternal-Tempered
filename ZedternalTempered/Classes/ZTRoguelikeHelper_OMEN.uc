/** "Doom Prophecy" - Wave start: random zed type Doomed. +100% dosh, heal 5 HP. */
class ZTRoguelikeHelper_OMEN extends ZTRoguelikeHelper;

var int DoomedKillHP;
const HEAL_PER_KILL = 5;
const DOOM_DAMAGE_BONUS = 0.25;

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn != None)
        OwnerPawn.Health = Min(OwnerPawn.Health + HEAL_PER_KILL, OwnerPawn.HealthMax);
}

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    return DOOM_DAMAGE_BONUS;
}

defaultproperties
{
    DoomedKillHP=0
    Name="Default__ZTRoguelikeHelper_OMEN"
}
