// ===================================================================
// ZTUpgrade_Skill_DarkPact_Helper
//
// Amplifies both blessing rewards and doom penalties.
//
// Standard: +50% reward, +50% doom
// Deluxe:   +75% reward, +50% doom
// ===================================================================
class ZTUpgrade_Skill_DarkPact_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var float RewardMultStandard;     // 1.5
var float RewardMultDeluxe;       // 1.75
var float DoomMultStandard;       // 1.5
var float DoomMultDeluxe;         // 1.5

function float GetRewardMultiplier()
{
    if (SkillLevel >= 2)
        return RewardMultDeluxe;

    return RewardMultStandard;
}

function float GetDoomMultiplier()
{
    if (SkillLevel >= 2)
        return DoomMultDeluxe;

    return DoomMultStandard;
}

defaultproperties
{
    RewardMultStandard=1.50f
    RewardMultDeluxe=1.75f
    DoomMultStandard=1.50f
    DoomMultDeluxe=1.50f

    Name="Default__ZTUpgrade_Skill_DarkPact_Helper"
}
