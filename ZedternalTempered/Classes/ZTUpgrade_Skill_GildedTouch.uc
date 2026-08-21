// ===================================================================
// ZTUpgrade_Skill_GildedTouch — Artificer Skill
//
// "Kills with mastered weapons cause the slain zed to erupt in a
//  Forge Detonation — an AoE explosion that damages nearby zeds.
//  Damage and radius scale with the number of mastery milestones
//  on the weapon that scored the kill."
//
// Works with ALL weapons that have ≥1 mastery milestone.
// Requires Artificer perk to be active (reads its helper's MasteryData).
//
// Normal:  Base 30 dmg + 20/milestone, 150 radius + 50/milestone
// Deluxe:  Base 50 dmg + 30/milestone, 200 radius + 60/milestone
//
// Hook: ModifyDamageGiven (kill detection → helper spawns explosion)
// Helper: ZTUpgrade_Skill_GildedTouch_Helper (explosion spawning)
// ===================================================================
class ZTUpgrade_Skill_GildedTouch extends ZTUpgrade_Skill config(ZedternalUnlimited);

// Explosion damage scaling
var config array<float> BaseDamage;
var config array<float> DamagePerMilestone;

// Explosion radius scaling
var config array<float> BaseRadius;
var config array<float> RadiusPerMilestone;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.BaseDamage[0] = 30.0f;
		default.BaseDamage[1] = 50.0f;
		default.DamagePerMilestone[0] = 20.0f;
		default.DamagePerMilestone[1] = 30.0f;
		default.BaseRadius[0] = 150.0f;
		default.BaseRadius[1] = 200.0f;
		default.RadiusPerMilestone[0] = 50.0f;
		default.RadiusPerMilestone[1] = 60.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.BaseDamage.Length = 2;
		default.BaseDamage[0] = 30.000000f;
		default.BaseDamage[1] = 50.000000f;
		default.DamagePerMilestone.Length = 2;
		default.DamagePerMilestone[0] = 20.000000f;
		default.DamagePerMilestone[1] = 30.000000f;
		default.BaseRadius.Length = 2;
		default.BaseRadius[0] = 150.000000f;
		default.BaseRadius[1] = 200.000000f;
		default.RadiusPerMilestone.Length = 2;
		default.RadiusPerMilestone[0] = 50.000000f;
		default.RadiusPerMilestone[1] = 60.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local ZTUpgrade_Skill_GildedTouch_Helper H;
    local string NormName;
    local int Milestones;
    local float ExploDmg, ExploRadius;

    if (DamageInstigator == None || DamageInstigator.Pawn == None || MyKFPM == None || MyKFW == None)
        return;

    // Only trigger on kills
    if (InDamage < MyKFPM.Health)
        return;

    // Find Artificer helper to check milestones
    ArtHelper = FindArtificerHelper(DamageInstigator.Pawn);
    if (ArtHelper == None)
        return;

    // Get milestones for the killing weapon
    NormName = class'ZTUpgrade_Perk_Artificer'.static.NormalizeWeaponName(string(MyKFW.Class.Name));
    Milestones = ArtHelper.GetMilestonesCompleted(NormName);

    // Must have at least 1 milestone
    if (Milestones <= 0)
        return;

    // Calculate scaled explosion parameters
    ExploDmg = default.BaseDamage[upgLevel - 1] + (default.DamagePerMilestone[upgLevel - 1] * float(Milestones));
    ExploRadius = default.BaseRadius[upgLevel - 1] + (default.RadiusPerMilestone[upgLevel - 1] * float(Milestones));

    // Get our helper and trigger the detonation
    H = GetHelper(DamageInstigator.Pawn, upgLevel);
    if (H != None)
        H.TriggerForgeDetonation(MyKFPM, ExploDmg, ExploRadius);
}

// ===================================================================
// ARTIFICER HELPER ACCESS
// ===================================================================

static function ZTUpgrade_Perk_Artificer_Helper FindArtificerHelper(Pawn P)
{
    local ZTUpgrade_Perk_Artificer_Helper H;

    if (P != None)
    {
        foreach P.ChildActors(class'ZTUpgrade_Perk_Artificer_Helper', H)
        {
            return H;
        }
    }

    return None;
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
        GetHelper(OwnerPawn, upgLevel);
}

static function ZTUpgrade_Skill_GildedTouch_Helper GetHelper(Pawn OwnerPawn, int upgLevel)
{
    local ZTUpgrade_Skill_GildedTouch_Helper H;

    if (KFPawn_Human(OwnerPawn) == None)
        return None;

    foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_GildedTouch_Helper', H)
    {
        H.UpgradeLevel = upgLevel;
        return H;
    }

    // Spawn if not found
    if (OwnerPawn.Role == ROLE_Authority)
    {
        H = OwnerPawn.Spawn(class'ZTUpgrade_Skill_GildedTouch_Helper', OwnerPawn);
        if (H != None)
            H.UpgradeLevel = upgLevel;
    }

    return H;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Skill_GildedTouch_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_GildedTouch_Helper', H)
        {
            H.Destroy();
        }
    }
}

defaultproperties
{
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Skill_GildedTouch]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Skill_GildedTouch"

    // Normal: small pops that scale up

    // Deluxe: bigger base, steeper scaling

    UpgradeName="Gilded Touch"
    UpgradeDescription(0)="Kills with <font color=\"#FFD700\">mastered weapons</font> trigger a <font color=\"#FFD700\">Forge Detonation</font>. Explosion scales with <font color=\"#FFFFFF\">mastery milestones</font>"
    UpgradeDescription(1)="Kills with <font color=\"#FFD700\">mastered weapons</font> trigger a <font color=\"#FFD700\">powerful Forge Detonation</font>. Explosion scales with <font color=\"#FFFFFF\">mastery milestones</font>"
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GildedTouch'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GildedTouch_Deluxe'

    Name="Default__ZTUpgrade_Skill_GildedTouch"
}
