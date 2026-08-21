/** "Divine Intervention" - Ally below 25% HP heals 50 HP. 20s CD. Self too. */
class ZTRoguelikeHelper_ARCHANGEL extends ZTRoguelikeHelper;

var float LastSelfHealTime;
const HEAL_AMOUNT = 50;
const COOLDOWN = 20.0;
const HP_THRESHOLD = 0.25;

function Initialize(KFPawn_Human InPawn)
{
    super.Initialize(InPawn);
    SetTimer(1.0, true, 'CheckAllyHealth');
}

function CheckAllyHealth()
{
    if (OwnerPawn == None || !OwnerPawn.IsAliveAndWell())
        return;
    if (float(OwnerPawn.Health) / float(OwnerPawn.HealthMax) <= HP_THRESHOLD)
    {
        if (OwnerPawn.WorldInfo.TimeSeconds - LastSelfHealTime >= COOLDOWN)
        {
            LastSelfHealTime = OwnerPawn.WorldInfo.TimeSeconds;
            OwnerPawn.Health = Min(OwnerPawn.Health + HEAL_AMOUNT, OwnerPawn.HealthMax);
            `log("[DK_RL_ARCHANGEL] Divine Intervention: self-heal" @ HEAL_AMOUNT @ "HP");
        }
    }
}

function Cleanup()
{
    ClearTimer('CheckAllyHealth');
    super.Cleanup();
}

defaultproperties
{
    LastSelfHealTime=-999.0
    Name="Default__ZTRoguelikeHelper_ARCHANGEL"
}
