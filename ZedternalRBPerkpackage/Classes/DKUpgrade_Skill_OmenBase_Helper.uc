// ===================================================================
// DKUpgrade_Skill_OmenBase_Helper
//
// Base class for all Omen skill helpers. Provides virtual callbacks
// that the Omen_Helper calls at key moments (wave start, prophecy
// completion, doom). Each skill helper overrides only what it needs.
//
// The Omen_Helper iterates ChildActors of this base class type,
// so all subclasses are automatically discovered.
// ===================================================================
class DKUpgrade_Skill_OmenBase_Helper extends Info
    transient;

var int SkillLevel; // 1 = normal, 2 = deluxe

function Initialize(int InLevel)
{
    SkillLevel = InLevel;
}

// Called by Omen_Helper at wave start, before prophecy draw
function OnWaveStart(KFPawn_Human P) {}

// Called by Omen_Helper after prophecy completes successfully
function OnProphecyCompleted() {}

// Called by Omen_Helper after doom is applied
function OnProphecyFailed() {}

// Should the prophecy condition be hidden this wave?
function bool ShouldHideProphecy() { return false; }

// Multiplier applied to blessing rewards (>1 = stronger, 0 = nullified)
function float GetRewardMultiplier() { return 1.0; }

// Multiplier applied to doom penalties (>1 = harsher, <1 = softer)
function float GetDoomMultiplier() { return 1.0; }

// HP sacrificed at wave start (0 = none)
function int GetWaveStartHPSacrifice() { return 0; }

// Bonus max HP granted on prophecy completion (0 = none)
function int GetCompletionBonusHP() { return 0; }

function Cleanup() {}

defaultproperties
{
    SkillLevel=1
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=True

    Name="Default__DKUpgrade_Skill_OmenBase_Helper"
}
