/** "Regenerating Fury" - Big hits trigger +5 HP/s for 10s. Kills extend 1s. */
class DKRoguelikeHelper_HYDRA extends DKRoguelikeHelper;

var float RegenEndTime;
const REGEN_RATE = 5;
const REGEN_DURATION = 10.0;
const KILL_EXTENSION = 1.0;
const BIG_HIT_THRESHOLD = 50;

function Initialize(KFPawn_Human InPawn)
{
    super.Initialize(InPawn);
    SetTimer(1.0, true, 'RegenTick');
}

function RegenTick()
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < RegenEndTime && OwnerPawn.IsAliveAndWell())
        OwnerPawn.Health = Min(OwnerPawn.Health + REGEN_RATE, OwnerPawn.HealthMax);
}

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    if (OwnerP != None && InDamage >= BIG_HIT_THRESHOLD && OwnerP.WorldInfo.TimeSeconds >= RegenEndTime)
    {
        RegenEndTime = OwnerP.WorldInfo.TimeSeconds + REGEN_DURATION;
        `log("[DK_RL_HYDRA] Regenerating Fury: regen started");
    }
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < RegenEndTime)
        RegenEndTime += KILL_EXTENSION;
}

function Cleanup()
{
    ClearTimer('RegenTick');
    super.Cleanup();
}

defaultproperties
{
    RegenEndTime=0.0
    Name="Default__DKRoguelikeHelper_HYDRA"
}
