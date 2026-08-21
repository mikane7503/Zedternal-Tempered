// ===================================================================
// ZTUpgrade_Skill_TwistOfFate_Helper
//
// When a prophecy completes, flip a coin:
//   50% chance: reward is DOUBLED
//   50% chance: you get NOTHING (but no doom either)
//
// Standard: 50/50 chance
// Deluxe:   55/45 chance (slightly favors double)
// ===================================================================
class ZTUpgrade_Skill_TwistOfFate_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var float DoubleChance;
var float DoubleChanceDeluxe;
var bool bLastFlipWasDouble;  // For HUD feedback

function Initialize(int InLevel)
{
    super.Initialize(InLevel);
    bLastFlipWasDouble = false;
}

function float GetRewardMultiplier()
{
    local float Chance;

    if (SkillLevel >= 2)
        Chance = DoubleChanceDeluxe;
    else
        Chance = DoubleChance;

    if (FRand() <= Chance)
    {
        bLastFlipWasDouble = true;
        `log("[DK_OMEN_SKILL] Twist of Fate: DOUBLE!");
        return 2.0f;
    }
    else
    {
        bLastFlipWasDouble = false;
        `log("[DK_OMEN_SKILL] Twist of Fate: NOTHING!");
        return 0.0f;
    }
}

defaultproperties
{
    DoubleChance=0.50f
    DoubleChanceDeluxe=0.55f
    bLastFlipWasDouble=false

    Name="Default__ZTUpgrade_Skill_TwistOfFate_Helper"
}
