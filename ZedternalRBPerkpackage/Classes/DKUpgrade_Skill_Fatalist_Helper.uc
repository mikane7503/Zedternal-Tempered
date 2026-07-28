// ===================================================================
// DKUpgrade_Skill_Fatalist_Helper
//
// Tracks which prophecy condition types have been completed via a
// bitmask (19 condition types, fits in a 32-bit int).
//
// Completing a condition type for the FIRST TIME grants boosted
// reward. Subsequent completions of the same type get normal reward.
//
// Flow:
//   1. Omen_Helper calls GetRewardMultiplier() - checks if bit is set
//   2. Omen_Helper calls OnProphecyCompleted() - sets the bit
//
// Standard: 1.5x reward for first-time condition types
// Deluxe:   2.0x reward for first-time condition types
// ===================================================================
class DKUpgrade_Skill_Fatalist_Helper extends DKUpgrade_Skill_OmenBase_Helper
    transient;

var int CompletedConditionMask;   // Bitmask of completed EProphecyCondition types
var float FirstTimeMult;          // Standard: 1.5
var float FirstTimeMultDeluxe;    // Deluxe: 2.0

function float GetRewardMultiplier()
{
    local DKUpgrade_Perk_Omen_Helper OH;
    local int CondBit;

    if (Owner == None)
        return 1.0f;

    // Find the Omen_Helper to read the active prophecy condition
    foreach Owner.ChildActors(class'DKUpgrade_Perk_Omen_Helper', OH)
    {
        if (OH.ActiveProphecyIndex >= 0 && OH.ActiveProphecyIndex < OH.ProphecyPool.Length)
        {
            CondBit = 1 << OH.ProphecyPool[OH.ActiveProphecyIndex].Condition;

            // Check if this condition type has been completed before
            if ((CompletedConditionMask & CondBit) == 0)
            {
                `log("[DK_OMEN_SKILL] Fatalist: First-time condition" @ OH.ProphecyPool[OH.ActiveProphecyIndex].Condition @ "- boosted reward!");
                if (SkillLevel >= 2)
                    return FirstTimeMultDeluxe;
                else
                    return FirstTimeMult;
            }
            else
            {
                `log("[DK_OMEN_SKILL] Fatalist: Repeat condition" @ OH.ProphecyPool[OH.ActiveProphecyIndex].Condition @ "- normal reward");
            }
        }
        break;
    }

    return 1.0f;
}

function OnProphecyCompleted()
{
    local DKUpgrade_Perk_Omen_Helper OH;
    local int CondBit;

    if (Owner == None)
        return;

    // Set the bit for the completed condition type
    foreach Owner.ChildActors(class'DKUpgrade_Perk_Omen_Helper', OH)
    {
        if (OH.ActiveProphecyIndex >= 0 && OH.ActiveProphecyIndex < OH.ProphecyPool.Length)
        {
            CondBit = 1 << OH.ProphecyPool[OH.ActiveProphecyIndex].Condition;
            CompletedConditionMask = CompletedConditionMask | CondBit;
            `log("[DK_OMEN_SKILL] Fatalist: Marked condition" @ OH.ProphecyPool[OH.ActiveProphecyIndex].Condition @ "as completed. Mask:" @ CompletedConditionMask);
        }
        break;
    }
}

defaultproperties
{
    CompletedConditionMask=0
    FirstTimeMult=1.50f
    FirstTimeMultDeluxe=2.00f

    Name="Default__DKUpgrade_Skill_Fatalist_Helper"
}
