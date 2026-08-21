/**
 * ZTRoguelikeHelper_WENDIGO — "Ravenous Consumption"
 * Large zed kills restore 25 HP and give +20% damage for 10s.
 * Killing 3 large zeds within a single wave grants +50 max HP permanently.
 */
class ZTRoguelikeHelper_WENDIGO extends ZTRoguelikeHelper;

var float LargeZedDamageBuffEndTime;
var int LargeZedKillsThisWave;
var bool bGrantedMaxHPThisWave;
var int TotalMaxHPBonus;

const HEAL_AMOUNT = 25;
const DAMAGE_BUFF = 0.20;
const DAMAGE_BUFF_DURATION = 10.0;
const KILLS_FOR_MAXHP = 3;
const MAXHP_BONUS = 50;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < LargeZedDamageBuffEndTime)
        return DAMAGE_BUFF;

    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (Killed == None || !Killed.IsLargeZed())
        return;

    // Heal
    if (OwnerPawn != None)
    {
        OwnerPawn.Health = Min(OwnerPawn.Health + HEAL_AMOUNT, OwnerPawn.HealthMax);
        `log("[DK_RL_WENDIGO] Ravenous Consumption: healed" @ HEAL_AMOUNT @ "HP");

        // Damage buff
        LargeZedDamageBuffEndTime = OwnerPawn.WorldInfo.TimeSeconds + DAMAGE_BUFF_DURATION;
    }

    // Track kills this wave for max HP bonus
    LargeZedKillsThisWave++;
    if (LargeZedKillsThisWave >= KILLS_FOR_MAXHP && !bGrantedMaxHPThisWave)
    {
        bGrantedMaxHPThisWave = true;
        TotalMaxHPBonus += MAXHP_BONUS;

        if (OwnerPawn != None)
        {
            OwnerPawn.HealthMax += MAXHP_BONUS;
            OwnerPawn.Health = Min(OwnerPawn.Health + MAXHP_BONUS, OwnerPawn.HealthMax);
            `log("[DK_RL_WENDIGO] Ravenous Consumption: +" @ MAXHP_BONUS @ "max HP! (total bonus:" @ TotalMaxHPBonus $ ")");
        }
    }
}

function OnWaveStart(int WaveNum)
{
    LargeZedKillsThisWave = 0;
    bGrantedMaxHPThisWave = false;
}

defaultproperties
{
    LargeZedDamageBuffEndTime=0.0
    LargeZedKillsThisWave=0
    bGrantedMaxHPThisWave=false
    TotalMaxHPBonus=0
    Name="Default__ZTRoguelikeHelper_WENDIGO"
}
