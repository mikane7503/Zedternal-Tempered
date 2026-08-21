// ===================================================================
// ZTUpgrade_Skill_DefiantStand_Helper
//
// After suffering doom, activates a 20s rage buff.
// The skill class reads bBuffActive for damage/DR/speed bonuses.
//
// Standard: +25% damage, +20% DR, +15% speed for 20s
// Deluxe:   +30% damage, +25% DR, +20% speed for 20s
// ===================================================================
class ZTUpgrade_Skill_DefiantStand_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var bool bBuffActive;
var float BuffEndTime;
var float BuffDuration;

function OnProphecyFailed()
{
    bBuffActive = true;
    BuffEndTime = WorldInfo.TimeSeconds + BuffDuration;
    `log("[DK_OMEN_SKILL] Defiant Stand: RAGE ACTIVATED for" @ BuffDuration @ "seconds");
}

function Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    if (bBuffActive && WorldInfo.TimeSeconds >= BuffEndTime)
    {
        bBuffActive = false;
        `log("[DK_OMEN_SKILL] Defiant Stand: Rage expired");
    }
}

defaultproperties
{
    bBuffActive=false
    BuffEndTime=0.0f
    BuffDuration=20.0f

    Name="Default__ZTUpgrade_Skill_DefiantStand_Helper"
}
