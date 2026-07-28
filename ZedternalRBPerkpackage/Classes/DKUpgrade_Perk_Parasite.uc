// ===================================================================
// DKUpgrade_Perk_Parasite - Vampiric Life-Drain Specialist
// Theme: Feed on enemy vitality - heal by hurting
// Color: Crimson Red (RGB: 180, 0, 40)
// Unlock Requirement: Field Medic Level 10 + Symbiote Level 10
// ===================================================================
class DKUpgrade_Perk_Parasite extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Passive scaling bonuses (Levels 1-20)
var config float LifeStealPerLevel;            // +2% life steal per level
var config float HealingReceivedPerLevel;      // +3% healing received per level
var config float SiphonDuration;               // Base siphon duration (4 seconds)
var config int SiphonDamagePerTick;            // Damage per DoT tick
var config int MaxSiphonedEnemies;             // Max enemies that can be siphoned

// Level 10 bonuses - "Siphon Network"
var config float DamagePerSiphonedEnemy;       // +4% damage per siphoning enemy
var config float HealingDamageRatio;           // 50% of healing dealt as damage to siphoned enemies

// Level 20 bonuses - "Crimson Tide"
var config int BloodHarvestKillsRequired;      // 20 kills while 3+ siphoning
var config int MinSiphonedForHarvest;          // Need 3+ siphoning enemies to count kills
var config float HemorrhagePulseDamage;        // 150 base AOE damage
var config float HemorrhagePulseRadius;        // 800 UU (8m)
var config float HemorrhageHealPercent;        // 100% of damage dealt heals self
var config float HemorrhageTeamHealPercent;    // 50% of damage dealt heals teammates
var config float DoubleLifeStealDuration;      // 8 seconds of 2x life steal

// Life steal cap per hit
var config int MaxLifeStealPerHit;             // Cap at 5 HP per hit
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.LifeStealPerLevel = 0.02f;
		default.HealingReceivedPerLevel = 0.03f;
		default.SiphonDuration = 4.0f;
		default.SiphonDamagePerTick = 5;
		default.MaxSiphonedEnemies = 8;
		default.DamagePerSiphonedEnemy = 0.04f;
		default.HealingDamageRatio = 0.50f;
		default.BloodHarvestKillsRequired = 20;
		default.MinSiphonedForHarvest = 3;
		default.HemorrhagePulseDamage = 150.0f;
		default.HemorrhagePulseRadius = 800.0f;
		default.HemorrhageHealPercent = 1.0f;
		default.HemorrhageTeamHealPercent = 0.50f;
		default.DoubleLifeStealDuration = 8.0f;
		default.MaxLifeStealPerHit = 5;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// Life Steal on Damage - Done via ModifyDamageGiven since we need actual damage dealt
// ===================================================================
static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, 
	KFPlayerController KFPC, class<DamageType> DT)
{
	// Life steal is handled in ModifyDamageGiven where we have access to actual damage
	// This function is kept for compatibility but does nothing
}

// ===================================================================
// Damage Modifier + Siphon Application + Life Steal
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_Parasite_Helper Helper;
	local float TotalBonus;
	local int SiphonedCount;
	local float LifeStealPercent;
	local int HealAmount;
	local KFPawn_Human PlayerPawn;
	
	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	
	if (MyKFPM == None)
		return;
	
	PlayerPawn = KFPawn_Human(DamageInstigator.Pawn);
	if (PlayerPawn == None)
		return;
	
	Helper = GetHelper(DamageInstigator.Pawn);
	if (Helper == None)
		return;
	
	// Level 10+ ("Siphon Network"): all damage applies Siphon AND grants
	// +damage per siphoned enemy. Applying Siphon is itself the capstone
	// ability, so it must be gated - previously it procced from level 1.
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level)
	{
		// Apply Siphon effect to damaged enemy
		Helper.ApplySiphon(MyKFPM);

		SiphonedCount = Helper.GetSiphonedEnemyCount();
		TotalBonus = default.DamagePerSiphonedEnemy * float(SiphonedCount);
		
		InDamage += Round(float(DefaultDamage) * TotalBonus);
	}
	
	// ===================================================================
	// LIFE STEAL - Heal based on damage dealt
	// GUARD: Skip life steal if this damage was caused by siphon feedback
	// or hemorrhage pulse. Without this check, life steal triggers
	// HealingDamage -> DamageSiphonedEnemies -> TakeDamage -> here again
	// causing infinite recursion (500 call stack overflow).
	// ===================================================================
	if (Helper.bIsSiphonDamage)
		return;
	
	LifeStealPercent = default.LifeStealPerLevel * upgLevel;
	
	// Double life steal during Hemorrhage buff
	if (Helper.IsDoubleLifeStealActive())
	{
		LifeStealPercent *= 2.0f;
	}
	
	// Calculate heal amount based on final damage
	HealAmount = Round(float(InDamage) * LifeStealPercent);
	
	// Cap life steal per hit
	HealAmount = Min(HealAmount, default.MaxLifeStealPerHit);
	
	if (HealAmount > 0)
	{
		PlayerPawn.HealDamage(HealAmount, DamageInstigator, class'KFDT_Healing');
	}
	
	// Track kills for Blood Harvest (Level 20)
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && MyKFPM != None && (MyKFPM.Health - InDamage) <= 0)
	{
		Helper.OnKillForBloodHarvest(MyKFPM);
	}
}

// ===================================================================
// Healing Received Bonus
// ===================================================================
static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	local float HealingBonus;
	
	// +3% healing received per level
	HealingBonus = default.HealingReceivedPerLevel * upgLevel;
	InHealAmount += DefaultHealAmount * HealingBonus;
}

// ===================================================================
// Level 10: Healing Teammates Damages Siphoned Enemies
// ===================================================================
static function HealingDamage(int upgLevel, int HealAmount, KFPawn HealedPawn, 
	KFPawn InstigatorPawn, class<DamageType> DamageType)
{
	local DKUpgrade_Perk_Parasite_Helper Helper;
	local int DamageToApply;
	
	if (upgLevel < class'DKConfig_Capstone'.default.Capstone_Rank1Level)
		return;
	
	if (InstigatorPawn == None)
		return;
	
	Helper = GetHelper(InstigatorPawn);
	if (Helper == None)
		return;
	
	// 50% of healing dealt damages nearby siphoned enemies
	DamageToApply = Round(float(HealAmount) * default.HealingDamageRatio);
	
	if (DamageToApply > 0)
	{
		Helper.DamageSiphonedEnemies(DamageToApply);
	}
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Parasite_Helper Helper;
	local KFPawn_Human HumanPawn;
	
	HumanPawn = KFPawn_Human(OwnerPawn);
	if (HumanPawn == None)
		return;
	
	// Only create helper on server
	if (OwnerPawn.Role != ROLE_Authority)
		return;
	
	// Check if helper already exists
	foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Parasite_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}
	
	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Parasite_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.Initialize(HumanPawn, upgLevel);
		`log("Parasite: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static function DKUpgrade_Perk_Parasite_Helper GetHelper(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Parasite_Helper Helper;
	
	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Parasite_Helper', Helper)
			return Helper;
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Parasite_Helper Helper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Parasite_Helper', Helper)
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
    // Section: [DKUpgrade_Perk_Parasite]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Parasite"
    LocalizeDescriptionLineCount=4

	// Passive bonuses (Levels 1-20)
	
	// Level 10 bonuses - "Siphon Network"
	
	// Level 20 bonuses - "Crimson Tide"
	
	// Life steal cap
	
	// UI and description
	upgradeName="Parasite"
	
	// PerkBonus for UI display
	PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Life steal %
	PerkBonus(1)=(baseValue=0, incValue=3, maxValue=-1)    // Healing received %
	PerkBonus(2)=(baseValue=4, incValue=0, maxValue=32)    // Siphon enemy bonus %
	PerkBonus(3)=(baseValue=0, incValue=0, maxValue=-1)    // Blood Harvest stacks
	
	upgradeDescription(0)="<font color=\"#B40028\">Blood Tithe:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6464\">Life Steal</font> on all damage (cap <font color=\"#FFFFFF\">5 HP</font> per hit)"
	upgradeDescription(1)="<font color=\"#B40028\">Vital Extraction:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FF6464\">Healing Received</font>"
	upgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Siphon Network</font> - All damage applies <font color=\"#B40028\">Siphon</font>. Gain <font color=\"#FFFFFF\">+%x%%</font> damage per siphoned enemy (max <font color=\"#FFFFFF\">8</font>). Healing teammates also damages siphoned enemies (<font color=\"#FFFFFF\">50%</font> of heal)"
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Crimson Tide</font> - Kills while <font color=\"#FFFFFF\">3+</font> enemies are siphoned charge <font color=\"#B40028\">Hemorrhage Pulse</font>. At <font color=\"#FFFFFF\">20</font> stacks: AOE drain heals team and grants <font color=\"#FFFFFF\">8s</font> of doubled <font color=\"#FF6464\">Life Steal</font>"
	
	// Icon references (21 total: Rank_0 through Rank_20)
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Parasite_Legacy_Rank_5'

	Name="Default__DKUpgrade_Perk_Parasite"
}
