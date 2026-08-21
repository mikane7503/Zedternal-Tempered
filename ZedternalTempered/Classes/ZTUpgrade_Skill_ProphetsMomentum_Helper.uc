// ===================================================================
// ZTUpgrade_Skill_ProphetsMomentum_Helper
//
// Tracks consecutive prophecy completions (streak).
// Each completion increments streak; any doom resets to 0.
// The skill class reads StreakCount for damage bonus.
// ===================================================================
class ZTUpgrade_Skill_ProphetsMomentum_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var int StreakCount;

function OnProphecyCompleted()
{
    StreakCount++;
    `log("[DK_OMEN_SKILL] Prophet's Momentum: Streak incremented to" @ StreakCount);
}

function OnProphecyFailed()
{
    if (StreakCount > 0)
        `log("[DK_OMEN_SKILL] Prophet's Momentum: Streak RESET from" @ StreakCount @ "to 0");

    StreakCount = 0;
}

defaultproperties
{
    StreakCount=0

    Name="Default__ZTUpgrade_Skill_ProphetsMomentum_Helper"
}
