// ===================================================================
// ZTUpgrade_Skill_Perfectionist_Helper
//
// Tracks a perfect prophecy record from the moment of purchase.
// Each completed prophecy increments PerfectWaveCount.
// The first doom permanently sets bPerfectRecord to false,
// destroying the entire damage bonus forever.
//
// Standard: +3% damage per perfect wave
// Deluxe:   +4% damage per perfect wave
// ===================================================================
class ZTUpgrade_Skill_Perfectionist_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var bool bPerfectRecord;
var int PerfectWaveCount;

function Initialize(int InLevel)
{
    super.Initialize(InLevel);
    bPerfectRecord = true;
    PerfectWaveCount = 0;
}

function OnProphecyCompleted()
{
    if (bPerfectRecord)
    {
        PerfectWaveCount++;
        `log("[DK_OMEN_SKILL] Perfectionist: Wave completed! Count:" @ PerfectWaveCount);
    }
}

function OnProphecyFailed()
{
    if (bPerfectRecord)
    {
        bPerfectRecord = false;
        `log("[DK_OMEN_SKILL] Perfectionist: RECORD BROKEN at" @ PerfectWaveCount @ "waves. Bonus permanently lost.");
    }
}

defaultproperties
{
    bPerfectRecord=true
    PerfectWaveCount=0

    Name="Default__ZTUpgrade_Skill_Perfectionist_Helper"
}
