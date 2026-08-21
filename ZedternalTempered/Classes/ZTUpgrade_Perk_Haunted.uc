// ===================================================================
// ZTUpgrade_Perk_Haunted - The Watcher Easter Egg
// Theme: Something is watching... always watching...
// Color: Dark Purple/Black (RGB: 40, 0, 60)
// Unlock Requirement: Berserker Level 10 + Field Medic Level 10
// Activation: purchasing Haunted awakens The Watcher immediately
// ===================================================================
class ZTUpgrade_Perk_Haunted extends ZTUpgrade_Perk config(ZedternalUnlimited);

// ===================================================================
// CONFIGURABLE WATCHER/DISASTER SETTINGS
// Change these to modify requirements
// ===================================================================

// Unlock conditions (to reveal Haunted in shop)
// These are handled by ZTMutator.InitializeDefaultPerkRules()
// Current: Berserker 10 + Field Medic 10

// Escalation settings
var config int KillsPerStage;                     // Kills needed to advance each stage
var config int MaxStage;                          // Maximum escalation stage (5)
var config int DisasterDamagePerLevel;            // Base global-disaster damage per Haunted level
var config float ExplosionDamageMultiplier;       // Explosion event damage multiplier
var config float DisasterMinWaveProgress;         // Earliest trigger point (0.30)
var config float DisasterMaxWaveProgress;         // Latest trigger point (0.70)
var config float DisasterWarningDuration;         // Caster-only warning lead time
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.KillsPerStage = 10;
		default.MaxStage = 5;
		default.DisasterDamagePerLevel = 100;
		default.ExplosionDamageMultiplier = 2.0f;
		default.DisasterMinWaveProgress = 0.30f;
		default.DisasterMaxWaveProgress = 0.70f;
		default.DisasterWarningDuration = 2.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.KillsPerStage = 10;
		default.MaxStage = 5;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 2)
	{
		default.DisasterDamagePerLevel = 100;
		default.ExplosionDamageMultiplier = 2.0f;
		default.DisasterMinWaveProgress = 0.30f;
		default.DisasterMaxWaveProgress = 0.70f;
		default.DisasterWarningDuration = 2.0f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// THE WATCHER
// Once per wave, triggers one random battlefield-wide disaster.
// ===================================================================

// ===================================================================
// Kill Tracking (for escalation)
// We hook ModifyDamageGiven just to track kills, not to modify damage
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Haunted_Helper Helper;
	
	// We don't modify damage at all - just track kills
	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	
	// Check if this damage would kill the target
	if (MyKFPM != None && (MyKFPM.Health - InDamage) <= 0)
	{
		Helper = GetHelper(DamageInstigator.Pawn);
		if (Helper != None)
		{
			Helper.OnKill();
		}
	}
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Haunted_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Haunted_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Haunted_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Haunted: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function ZTUpgrade_Perk_Haunted_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Haunted_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Haunted_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Haunted_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Haunted_Helper', Helper)
		{
			Helper.Cleanup();
			Helper.Destroy();
		}
	}
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Haunted_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Haunted]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Haunted"
    LocalizeDescriptionLineCount=4

	// Escalation settings
	
	// UI and description
	upgradeName="???"
	
	// PerkBonus - None (this perk grants no bonuses)
	// Empty array = no bonus display
	
	upgradeDescription(0)="Once per wave at <font color=\"#CC66FF\">30-70% progress</font>, The Watcher triggers one random global disaster."
	upgradeDescription(1)="All active zeds are randomly <font color=\"#66CCFF\">frozen</font>, <font color=\"#FF9900\">exploded</font>, <font color=\"#CCCCCC\">knocked down</font>, or <font color=\"#FF3300\">ignited</font>."
	upgradeDescription(2)="Disaster damage: <font color=\"#FFFFFF\">100 per Haunted level</font>. Explosion damage is doubled."
	upgradeDescription(3)="The caster receives a Watcher visual warning <font color=\"#CC66FF\">2 seconds before activation</font>."
	
	// Icon references - You'll create these
	// For now using placeholder paths - update these with your actual icons

	Name="Default__ZTUpgrade_Perk_Haunted"
}
