// ===================================================================
// PerkFilterConfig - Perk Unlock Rules Configuration
//
// Manages:
// - Achievement-locked perks (hidden until unlocked)
// - Prerequisite unlock rules (need perk X at level Y to see perk Z)
// - Mutual exclusion rules (buying perk A hides perk B, and vice versa)
// ===================================================================
class PerkFilterConfig extends Object;

// ===================================================================
// STRUCTS
// ===================================================================

struct PerkUnlockRule
{
    var string PerkClassName;
    var array<string> RequiredPerks;
    var array<int> RequiredPerkLevels;
};

// Bidirectional exclusion — buying either perk hides the other
struct PerkExclusionRule
{
    var string PerkA;
    var string PerkB;
};

// ===================================================================
// VARIABLES
// ===================================================================

var array<PerkUnlockRule> UnlockRules;
var array<string> AchievementLockedPerks;
var array<PerkExclusionRule> ExclusionRules;

// ===================================================================
// UNLOCK RULES (prerequisite perks)
// ===================================================================

function AddUnlockRule(string LockedPerk, string Req1, int Req1Level,
    optional string Req2, optional int Req2Level)
{
    local PerkUnlockRule NewRule;

    NewRule.PerkClassName = LockedPerk;

    NewRule.RequiredPerks.AddItem(Req1);
    NewRule.RequiredPerkLevels.AddItem(Req1Level);

    if (Req2 != "")
    {
        NewRule.RequiredPerks.AddItem(Req2);
        NewRule.RequiredPerkLevels.AddItem(Req2Level);
    }

    UnlockRules.AddItem(NewRule);
}

// ===================================================================
// ACHIEVEMENT LOCKS
// ===================================================================

function AddAchievementLockedPerk(string PerkClassName)
{
    if (AchievementLockedPerks.Find(PerkClassName) == INDEX_NONE)
    {
        AchievementLockedPerks.AddItem(PerkClassName);
    }
}

function bool IsAchievementLocked(string PerkClassName)
{
    local int i;

    for (i = 0; i < AchievementLockedPerks.Length; i++)
    {
        if (AchievementLockedPerks[i] ~= PerkClassName)
            return true;
    }

    return false;
}

// ===================================================================
// MUTUAL EXCLUSION RULES
// ===================================================================

// Add a bidirectional exclusion: buying PerkA at Rank 1+ hides PerkB,
// and buying PerkB at Rank 1+ hides PerkA.
function AddExclusionRule(string PerkA, string PerkB)
{
    local PerkExclusionRule NewRule;
    local int i;

    // Check for duplicates
    for (i = 0; i < ExclusionRules.Length; i++)
    {
        if ((ExclusionRules[i].PerkA ~= PerkA && ExclusionRules[i].PerkB ~= PerkB)
            || (ExclusionRules[i].PerkA ~= PerkB && ExclusionRules[i].PerkB ~= PerkA))
        {
            return; // already exists
        }
    }

    NewRule.PerkA = PerkA;
    NewRule.PerkB = PerkB;
    ExclusionRules.AddItem(NewRule);
}

// Check if a perk should be excluded (hidden) based on what the player
// has already purchased. Returns true if the perk should be HIDDEN.
//
// OwnedPerkNames: array of perk class names the player owns at level 1+
// CandidatePerk: the perk being checked for visibility
function bool IsPerkExcluded(string CandidatePerk, array<string> OwnedPerkNames)
{
    local int i, j;

    for (i = 0; i < ExclusionRules.Length; i++)
    {
        // If candidate is PerkA, check if player owns PerkB
        if (ExclusionRules[i].PerkA ~= CandidatePerk)
        {
            for (j = 0; j < OwnedPerkNames.Length; j++)
            {
                if (OwnedPerkNames[j] ~= ExclusionRules[i].PerkB)
                    return true;
            }
        }

        // If candidate is PerkB, check if player owns PerkA
        if (ExclusionRules[i].PerkB ~= CandidatePerk)
        {
            for (j = 0; j < OwnedPerkNames.Length; j++)
            {
                if (OwnedPerkNames[j] ~= ExclusionRules[i].PerkA)
                    return true;
            }
        }
    }

    return false;
}

// Convenience: check exclusion using a single owned perk name
// (useful when checking at purchase time)
function bool ArePerksExclusive(string PerkA, string PerkB)
{
    local int i;

    for (i = 0; i < ExclusionRules.Length; i++)
    {
        if ((ExclusionRules[i].PerkA ~= PerkA && ExclusionRules[i].PerkB ~= PerkB)
            || (ExclusionRules[i].PerkA ~= PerkB && ExclusionRules[i].PerkB ~= PerkA))
        {
            return true;
        }
    }

    return false;
}

defaultproperties
{
    Name="Default__PerkFilterConfig"
}
