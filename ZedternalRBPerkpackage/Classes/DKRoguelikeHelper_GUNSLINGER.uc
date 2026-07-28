/**
 * DKRoguelikeHelper_GUNSLINGER — "Fan the Hammer"
 * After headshot kill: next 3 shots within 2s have +50% fire rate and zero recoil.
 * 5s cooldown after the burst expires.
 */
class DKRoguelikeHelper_GUNSLINGER extends DKRoguelikeHelper;

var int BurstShotsRemaining;
var float BurstExpireTime;
var float BurstCooldownEnd;

const BURST_SHOTS = 3;
const BURST_WINDOW = 2.0;
const BURST_COOLDOWN = 5.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    // The damage bonus is 0 — the real effect is fire rate/recoil (handled elsewhere)
    // But we track burst shot consumption here since this is called per hit
    if (BurstShotsRemaining > 0 && OwnerPawn != None)
    {
        if (OwnerPawn.WorldInfo.TimeSeconds < BurstExpireTime)
        {
            BurstShotsRemaining--;
            if (BurstShotsRemaining <= 0)
            {
                BurstCooldownEnd = OwnerPawn.WorldInfo.TimeSeconds + BURST_COOLDOWN;
                `log("[DK_RL_GUNSLINGER] Fan the Hammer: burst consumed");
            }
        }
        else
        {
            // Expired before all shots used
            BurstShotsRemaining = 0;
            BurstCooldownEnd = OwnerPawn.WorldInfo.TimeSeconds + BURST_COOLDOWN;
        }
    }

    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (HitZoneIdx != HZI_HEAD)
        return;

    if (OwnerPawn == None)
        return;

    // Check cooldown
    if (OwnerPawn.WorldInfo.TimeSeconds < BurstCooldownEnd)
        return;

    // Activate burst
    BurstShotsRemaining = BURST_SHOTS;
    BurstExpireTime = OwnerPawn.WorldInfo.TimeSeconds + BURST_WINDOW;
    `log("[DK_RL_GUNSLINGER] Fan the Hammer: ACTIVATED — 3 shots, 2s window");
}

/** Check if burst is currently active (called from DKPerk for recoil/fire rate) */
function bool IsBurstActive()
{
    if (BurstShotsRemaining > 0 && OwnerPawn != None)
        return (OwnerPawn.WorldInfo.TimeSeconds < BurstExpireTime);

    return false;
}

defaultproperties
{
    BurstShotsRemaining=0
    BurstExpireTime=0.0
    BurstCooldownEnd=0.0
    Name="Default__DKRoguelikeHelper_GUNSLINGER"
}
