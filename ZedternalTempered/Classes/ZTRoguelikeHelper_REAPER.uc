/** "Soul Harvest" - Kills grant Souls (max 50). At 50: +200% next hit. Decay 2/s after 5s idle. */
class ZTRoguelikeHelper_REAPER extends ZTRoguelikeHelper;

var int Souls;
var float LastKillTime;
var bool bSoulBurstReady;

const MAX_SOULS = 50;
const BURST_DAMAGE = 2.00;
const DECAY_RATE = 2;
const DECAY_DELAY = 5.0;

function Initialize(KFPawn_Human InPawn)
{
    super.Initialize(InPawn);
    SetTimer(1.0, true, 'DecaySouls');
}

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (bSoulBurstReady)
    {
        bSoulBurstReady = false;
        Souls = 0;
        `log("[DK_RL_REAPER] Soul Harvest: BURST! +200% damage");
        return BURST_DAMAGE;
    }
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn != None)
        LastKillTime = OwnerPawn.WorldInfo.TimeSeconds;

    if (Souls < MAX_SOULS)
    {
        Souls++;
        if (Souls >= MAX_SOULS)
        {
            bSoulBurstReady = true;
            `log("[DK_RL_REAPER] Soul Harvest: MAX SOULS!");
        }
    }
}

function DecaySouls()
{
    if (OwnerPawn == None)
        return;
    if (Souls > 0 && !bSoulBurstReady)
    {
        if (OwnerPawn.WorldInfo.TimeSeconds - LastKillTime >= DECAY_DELAY)
            Souls = Max(Souls - DECAY_RATE, 0);
    }
}

function Cleanup()
{
    ClearTimer('DecaySouls');
    super.Cleanup();
}

defaultproperties
{
    Souls=0
    LastKillTime=0.0
    bSoulBurstReady=false
    Name="Default__ZTRoguelikeHelper_REAPER"
}
