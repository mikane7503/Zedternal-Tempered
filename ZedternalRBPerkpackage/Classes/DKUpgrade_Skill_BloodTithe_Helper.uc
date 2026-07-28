// ===================================================================
// DKUpgrade_Skill_BloodTithe_Helper
//
// At wave start, sacrifice 10 HP.
// If the prophecy completes, gain permanent max HP.
//
// Standard: sacrifice 10, gain +15 max HP (net +5)
// Deluxe:   sacrifice 10, gain +20 max HP (net +10)
// ===================================================================
class DKUpgrade_Skill_BloodTithe_Helper extends DKUpgrade_Skill_OmenBase_Helper
    transient;

var int HPSacrifice;
var int HPReward;           // Standard: 15
var int HPRewardDeluxe;     // Deluxe: 20

function int GetWaveStartHPSacrifice()
{
    return HPSacrifice;
}

function int GetCompletionBonusHP()
{
    if (SkillLevel >= 2)
        return HPRewardDeluxe;
    else
        return HPReward;
}

defaultproperties
{
    HPSacrifice=10
    HPReward=15
    HPRewardDeluxe=20

    Name="Default__DKUpgrade_Skill_BloodTithe_Helper"
}
