// ===================================================================
// DKUpgrade_Perk_Agony - ZED Time Master
// Theme: Dominate ZED time with movement speed and freeze control
// Color: Purple/Violet (RGB: 150, 50, 255)
// ===================================================================
class DKUpgrade_Perk_Agony extends DKUpgrade_Perk
	config(ZedternalUnlimited);

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
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
		MovementBonus += default.Level10Movement;
	
	// Level 20 bonus: +60% additional (100% total = full normal speed)
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
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
	local DKUpgrade_Perk_Agony_Helper Helper;
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
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
		DamageBonus += default.Level10Damage;
	
	// Level 20 bonus: +50% additional
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
		DamageBonus += default.Level20Damage;
	
	InDamage += Round(float(DefaultDamage) * DamageBonus);
	
	// Level 10+: 30% chance to extend ZED time on headshot
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && HitZoneIdx == HZI_HEAD && MyKFPM != None)
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
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
	{
		InExtension += 9999.0f;  // Effectively infinite extensions
	}
	else if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
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
	local DKUpgrade_Perk_Agony_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Agony_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Agony_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Agony: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function DKUpgrade_Perk_Agony_Helper GetHelper(KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Agony_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Agony_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Agony_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Agony_Helper', Helper)
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
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Agony]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Agony"
    LocalizeDescriptionLineCount=4

	// Passive bonuses
	
	// Level 10 bonuses
	
	// Level 20 bonuses
	
	// Headshot extension cooldown
	
	// UI and description
	upgradeName="Agony"
	
	// PerkBonus for UI display
	PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Movement %
	PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Damage %
	PerkBonus(2)=(baseValue=30, incValue=0, maxValue=30)   // Headshot extension chance %
	PerkBonus(3)=(baseValue=0, incValue=0, maxValue=0)     // Reserved for ZED time tracker
	
	upgradeDescription(0)="<font color=\"#9632ff\">Temporal Acceleration:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#d8b0ff\">Movement Speed</font> during ZED Time"
	upgradeDescription(1)="<font color=\"#9632ff\">Time Distortion:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#d8b0ff\">Damage</font> during ZED Time"
	upgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Temporal Mastery</font> - <font color=\"#FFFFFF\">+40%</font> <font color=\"#d8b0ff\">Movement Speed</font>, <font color=\"#FFFFFF\">+30%</font> <font color=\"#d8b0ff\">Damage</font> in ZED Time. Headshots have <font color=\"#FFFFFF\">30%</font> chance to <font color=\"#d8b0ff\">extend ZED Time</font>"
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Time Banker</font> - <font color=\"#FFFFFF\">+60%</font> <font color=\"#d8b0ff\">Movement Speed</font> (full normal speed), <font color=\"#FFFFFF\">+50%</font> <font color=\"#d8b0ff\">Damage</font> in ZED Time. <font color=\"#d8b0ff\">Uncapped extensions</font>. Earn <font color=\"#FFFFFF\">500 Dosh</font> per <font color=\"#FFFFFF\">120s</font> spent in ZED Time"
	
	// Icon references (21 total: Rank_0 through Rank_20)
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Agony_Legacy_Rank_5'

	Name="Default__DKUpgrade_Perk_Agony"
}