// ===================================================================
// ZTUpgrade_Perk_Agony - ZED Time Master
// Theme: Dominate ZED time with movement speed and freeze control
// Color: Purple/Violet (RGB: 150, 50, 255)
// ===================================================================
class ZTUpgrade_Perk_Agony extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Passive scaling bonuses
var config float MovementPerLevel;        // +2% movement speed during ZED time per level
var config float DamagePerLevel;          // +2% damage during ZED time per level

// Level 10 bonuses
var config float Level10Movement;         // +40% movement speed during ZED time
var config float Level10Damage;           // +30% damage during ZED time
var config float HeadshotExtensionChance; // 30% chance to extend on headshot

// Level 20 bonuses
var config float Level20Movement;         // +60% movement speed during ZED time (100% total - full normal speed)
var config float Level20Damage;           // +50% damage during ZED time

// Headshot extension tracking
var config float HeadshotExtensionCooldown;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MovementPerLevel = 0.02f;
		default.DamagePerLevel = 0.02f;
		default.Level10Movement = 0.40f;
		default.Level10Damage = 0.30f;
		default.HeadshotExtensionChance = 0.30f;
		default.Level20Movement = 0.60f;
		default.Level20Damage = 0.50f;
		default.HeadshotExtensionCooldown = 0.1f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.MovementPerLevel = 0.010000f;
		default.DamagePerLevel = 0.020000f;
		default.Level10Movement = 0.200000f;
		default.Level10Damage = 0.150000f;
		default.HeadshotExtensionChance = 0.100000f;
		default.Level20Movement = 0.300000f;
		default.Level20Damage = 0.250000f;
		default.HeadshotExtensionCooldown = 8.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// Movement Speed Bonus ONLY During ZED Time
// ===================================================================
static simulated function ModifySpeed(out float InSpeedFactor, float DefaultSpeedFactor, 
	int upgLevel, KFPawn OwnerPawn)
{
	local float MovementBonus;
	
	if (OwnerPawn == None)
		return;
	
	// Only apply during ZED time
	if (OwnerPawn.WorldInfo.TimeDilation >= 1.0)
		return;
	
	// Base passive movement scaling (levels 1-20): +2% per level
	MovementBonus = default.MovementPerLevel * upgLevel;
	
	// Level 10 bonus: +40% additional
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
		MovementBonus += default.Level10Movement;
	
	// Level 20 bonus: +60% additional (100% total = full normal speed)
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
		MovementBonus += default.Level20Movement;
	
	InSpeedFactor += MovementBonus;
}

// ===================================================================
// Damage Bonus During ZED Time
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local KFPawn OwnerPawn;
	local ZTUpgrade_Perk_Agony_Helper Helper;
	local float DamageBonus;
	
	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
		
	OwnerPawn = KFPawn(DamageInstigator.Pawn);
	if (OwnerPawn == None)
		return;
	
	// Check if ZED time is active
	if (OwnerPawn.WorldInfo.TimeDilation >= 1.0)
		return;
	
	// Base passive damage scaling (levels 1-20): +2% per level
	DamageBonus = default.DamagePerLevel * upgLevel;
	
	// Level 10 bonus: +30% additional
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
		DamageBonus += default.Level10Damage;
	
	// Level 20 bonus: +50% additional
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
		DamageBonus += default.Level20Damage;
	
	InDamage += Round(float(DefaultDamage) * DamageBonus);
	
	// Level 10+: 30% chance to extend ZED time on headshot
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && HitZoneIdx == HZI_HEAD && MyKFPM != None)
	{
		Helper = GetHelper(OwnerPawn);
		if (Helper != None)
			Helper.TryHeadshotExtension(OwnerPawn);
	}
}

// ===================================================================
// ZED Time Extension Cap Override (Level 20: Infinite Extensions)
// ===================================================================
static simulated function GetZedTimeExtension(out float InExtension, float DefaultExtension, int upgLevel)
{
	// Level 20: Return massive value to bypass extension limit check in KFGameInfo
	// This allows infinite ZED time extensions via headshot procs
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
	{
		InExtension += 9999.0f;  // Effectively infinite extensions
	}
	else if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
	{
		// Level 10-19: Allow limited extensions (normal game behavior)
		InExtension += 5.0f;  // Allow up to 5 extensions
	}
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Agony_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Agony_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Agony_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Agony: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function ZTUpgrade_Perk_Agony_Helper GetHelper(KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Agony_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Agony_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Agony_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Agony_Helper', Helper)
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
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Agony]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Agony"
    LocalizeDescriptionLineCount=4

	// Passive bonuses
	
	// Level 10 bonuses
	
	// Level 20 bonuses
	
	// Headshot extension cooldown
	
	// UI and description
	upgradeName="Agony"
	
	// PerkBonus for UI display
	PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)    // Movement %
	PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Damage %
	PerkBonus(2)=(baseValue=10, incValue=0, maxValue=10)   // Headshot extension chance %
	PerkBonus(3)=(baseValue=0, incValue=0, maxValue=0)     // Reserved for ZED time tracker
	
	upgradeDescription(0)="<font color=\"#9632ff\">Temporal Acceleration:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#d8b0ff\">Movement Speed</font> during ZED Time"
	upgradeDescription(1)="<font color=\"#9632ff\">Time Distortion:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#d8b0ff\">Damage</font> during ZED Time"
	upgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Temporal Mastery</font> - <font color=\"#FFFFFF\">+20%</font> <font color=\"#d8b0ff\">Movement Speed</font>, <font color=\"#FFFFFF\">+15%</font> <font color=\"#d8b0ff\">Damage</font> in ZED Time. Headshots have <font color=\"#FFFFFF\">10%</font> chance to <font color=\"#d8b0ff\">extend ZED Time</font>"
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Time Banker</font> - <font color=\"#FFFFFF\">+30%</font> <font color=\"#d8b0ff\">Movement Speed</font> (full normal speed), <font color=\"#FFFFFF\">+25%</font> <font color=\"#d8b0ff\">Damage</font> in ZED Time. <font color=\"#d8b0ff\">Uncapped extensions</font>. Earn <font color=\"#FFFFFF\">500 Dosh</font> per <font color=\"#FFFFFF\">120s</font> spent in ZED Time"
	
	// Icon references (21 total: Rank_0 through Rank_20)
	
	// Legacy (hand-made) artwork icons

	Name="Default__ZTUpgrade_Perk_Agony"
}