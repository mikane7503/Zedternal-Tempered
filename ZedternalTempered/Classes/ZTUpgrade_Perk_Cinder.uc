// ===================================================================
// ZTUpgrade_Perk_Cinder - Living Inferno
// Theme: Feed the flames - grow stronger as more enemies burn
// Color: Orange/Red (RGB: 255, 100, 0)
// Unlock Requirement: Firebug Level 10 + Symbiote Level 10
// ===================================================================
class ZTUpgrade_Perk_Cinder extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Passive scaling bonuses (Levels 1-20)
var config float FireDamagePerLevel;           // +3% fire damage per level
var config float BurningTargetDamagePerLevel;  // +2% damage to burning enemies per level
var config float BurnDurationPerLevel;         // +0.2 seconds burn duration per 5 levels

// Level 10 bonuses - "Symbiotic Synergy"
var config float DamagePerBurningEnemy;        // +5% fire damage per burning enemy
var config int MaxBurningEnemyBonus;           // Cap at 10 enemies
var config float FireSpreadBonus;              // 30% faster fire spread
var config float BurningEnemyFireResist;       // -10% fire resistance for burning enemies

// Level 20 bonuses - "Phoenix Protocol"
var config float Level20DamagePerBurningEnemy; // +8% fire damage per burning enemy
var config float PhoenixDamageReduction;       // 50% damage reduction during Last Stand
var config float PhoenixDuration;              // 5 seconds Last Stand
var config float PhoenixRadius;                // 10m ignition radius
var config float PermanentBonusPerKills;       // +1% fire damage per 100 fire kills

// Phoenix Protocol tracking
var bool bPhoenixProtocolUsed;          // Once per wave
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.FireDamagePerLevel = 0.03f;
		default.BurningTargetDamagePerLevel = 0.02f;
		default.BurnDurationPerLevel = 0.2f;
		default.DamagePerBurningEnemy = 0.05f;
		default.MaxBurningEnemyBonus = 10;
		default.FireSpreadBonus = 0.30f;
		default.BurningEnemyFireResist = 0.10f;
		default.Level20DamagePerBurningEnemy = 0.08f;
		default.PhoenixDamageReduction = 1.0f;
		default.PhoenixDuration = 10.0f;
		default.PhoenixRadius = 1000.0f;
		default.PermanentBonusPerKills = 0.01f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.FireDamagePerLevel = 0.015000f;
		default.BurningTargetDamagePerLevel = 0.010000f;
		default.BurnDurationPerLevel = 0.100000f;
		default.DamagePerBurningEnemy = 0.025000f;
		default.MaxBurningEnemyBonus = 10;
		default.FireSpreadBonus = 0.150000f;
		default.BurningEnemyFireResist = 0.050000f;
		default.Level20DamagePerBurningEnemy = 0.040000f;
		default.PhoenixDamageReduction = 0.250000f;
		default.PhoenixDuration = 10.000000f;
		default.PhoenixRadius = 1000.000000f;
		default.PermanentBonusPerKills = 0.005000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// Fire Damage Bonus
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Cinder_Helper Helper;
	local float TotalBonus;
	local int BurningCount;
	local float PermanentBonus;
	
	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	
	// Only apply to fire damage
	if (!ClassIsChildOf(DamageType, class'KFDT_Fire'))
	{
		// Still apply bonus damage to already-burning targets
		if (MyKFPM != None && MyKFPM.IsDoingSpecialMove(SM_Frozen) == false)
		{
			if (IsBurning(MyKFPM))
			{
				TotalBonus = default.BurningTargetDamagePerLevel * upgLevel;
				InDamage += Round(float(DefaultDamage) * TotalBonus);
			}
		}
		return;
	}
	
	// Base fire damage scaling (levels 1-20): +3% per level
	TotalBonus = default.FireDamagePerLevel * upgLevel;
	
	// Get helper for burning enemy count - FIXED: removed unnecessary KFPawn cast
	Helper = GetHelper(DamageInstigator.Pawn);
	if (Helper != None)
	{
		BurningCount = Helper.GetBurningEnemyCount();
		PermanentBonus = Helper.GetPermanentBonus();
		
		// Level 10+: +5% per burning enemy (max 10)
		if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
		{
			TotalBonus += default.DamagePerBurningEnemy * float(BurningCount);
		}
		
		// Level 20: Increased to +8% per burning enemy
		if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
		{
			TotalBonus += (default.Level20DamagePerBurningEnemy - default.DamagePerBurningEnemy) * float(BurningCount);
		}
		
		// Add permanent bonus from fire kills
		TotalBonus += PermanentBonus;
	}
	
	InDamage += Round(float(DefaultDamage) * TotalBonus);
	
	// Track fire kills for permanent bonus
	if (Helper != None && MyKFPM != None && (MyKFPM.Health - InDamage) <= 0)
	{
		Helper.OnFireKill();
	}
}

// ===================================================================
// Burn Duration Extension
// ===================================================================
static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, 
	optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	local float DurationBonus;
	
	if (!ClassIsChildOf(KFDT, class'KFDT_Fire'))
		return;
	
	// +0.2 seconds per 5 levels (4 seconds extra at level 20)
	// FIXED: removed redundant int() cast - division already returns int
	DurationBonus = (upgLevel / 5) * default.BurnDurationPerLevel;
	InDoTScaler += DurationBonus;
}

// ===================================================================
// Level 20: Phoenix Protocol - Last Stand on Death
// ===================================================================
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
	KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy,
	optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Cinder_Helper Helper;
	
	if (upgLevel < class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
		return;
	
	Helper = GetHelper(OwnerPawn);
	if (Helper == None)
		return;
	
	// Phoenix Protocol damage reduction during Last Stand
	if (Helper.bInPhoenixProtocol)
	{
		InDamage = Round(float(InDamage) * (1.0f - default.PhoenixDamageReduction));
		`log("Cinder: Phoenix Protocol granting" @ (default.PhoenixDamageReduction * 100) $ "%");
	}
	
	// Check if this damage would kill the player
	if (OwnerPawn != None && (OwnerPawn.Health - InDamage) <= 0)
	{
		// Try to trigger Phoenix Protocol
		if (!Helper.bPhoenixProtocolUsedThisWave)
		{
			Helper.TriggerPhoenixProtocol();
			// Prevent death
			InDamage = OwnerPawn.Health - 1;
			`log("Cinder: Phoenix Protocol ACTIVATED! Prevented death");
		}
	}
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Cinder_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cinder_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Cinder_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Cinder: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function ZTUpgrade_Perk_Cinder_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Cinder_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cinder_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Cinder_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Cinder_Helper', Helper)
		{
			Helper.Cleanup();
			Helper.Destroy();
		}
	}
}

// ===================================================================
// Utility Functions
// ===================================================================
static function bool IsBurning(KFPawn_Monster Monster)
{
	local int i;
	
	if (Monster == None)
		return false;
	
	// Check if monster has fire DoT active
	for (i = 0; i < Monster.DamageOverTimeArray.Length; i++)
	{
		if (Monster.DamageOverTimeArray[i].DoT_Type == DOT_Fire)
			return true;
	}
	
	return false;
}

// ===================================================================
// Default Properties
// ===================================================================
defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Cinder_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Cinder]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Cinder"
    LocalizeDescriptionLineCount=5

	// Passive bonuses (Levels 1-20)
	
	// Level 10 bonuses - "Symbiotic Synergy"
	
	// Level 20 bonuses - "Phoenix Protocol"
	
	// UI and description
	upgradeName="Cinder"
	
	// PerkBonus for UI display
	PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Fire damage %
	PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)    // Burning target damage %
	PerkBonus(2)=(baseValue=3, incValue=0, maxValue=50)    // Burning enemy bonus %
	PerkBonus(3)=(baseValue=0, incValue=1, maxValue=-1)    // Permanent fire kill bonus
	
	upgradeDescription(0)="<font color=\"#FF6400\">Pyroclasm:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C32\">Fire Damage</font>"
	upgradeDescription(1)="<font color=\"#FF6400\">Inferno:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF8C32\">Damage to Burning Enemies</font>"
	upgradeDescription(2)="<font color=\"#FF6400\">Lingering Flames:</font> <font color=\"#FFFFFF\">+0.1s</font> <font color=\"#FF8C32\">Burn Duration</font> per 5 ranks"
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 5:</font> <font color=\"#FFD700\">Symbiotic Synergy</font> - <font color=\"#FFFFFF\">+2.5%</font> fire damage per burning enemy (max <font color=\"#FFFFFF\">5</font>). Fire spreads <font color=\"#FFFFFF\">15%</font> faster. Burning enemies have <font color=\"#FFFFFF\">-5%</font> fire resist"
	upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Phoenix Protocol</font> - <font color=\"#FFFFFF\">+4%</font> fire damage per burning enemy. Gain <font color=\"#FFFFFF\">+0.5%</font> permanent fire damage per <font color=\"#FFFFFF\">100</font> fire kills. Cheat death once per wave (<font color=\"#FFFFFF\">10s</font> of 25% damage reduction)"
	
	// Icon references (21 total: Rank_0 through Rank_20)
	
	// Legacy (hand-made) artwork icons

	Name="Default__ZTUpgrade_Perk_Cinder"
}