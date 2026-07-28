class DKUpgrade_Perk_Riot extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Theme: "Riot" - A melee fighter who thrives when surrounded by enemies
// Gets stronger the more enemies are nearby, eventually becoming unstoppable in crowds

// Passive bonuses per level
var config float MeleeDamagePerLevel;        // Base melee damage bonus per level
var config float DamageResistancePerLevel;   // Base damage resistance per level
var config float AttackSpeedPerLevel;        // Base attack speed bonus per level

// Level 10 - "In the Thick of It"
var config float DamagePerNearbyEnemy;       // Damage bonus per nearby enemy
var config float ResistancePerNearbyEnemy;   // Resistance bonus per nearby enemy
var config int MaxNearbyEnemies;             // Cap on nearby enemy bonuses
var config float NearbyEnemyRadius;          // Radius to check for enemies (in meters)

// Level 20 - "Riot Control"
var config int StumbleImmunityThreshold;     // Enemies needed for stumble immunity (3)
var config int MaxBonusThreshold;            // Enemies needed for max bonuses (5)
var config float RiotMovementSpeedBonus;     // Movement speed when at max threshold
var config float RiotAttackSpeedBonus;       // Attack speed when at max threshold
var config float RiotLinger;                 // How long bonuses last after enemies leave
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MeleeDamagePerLevel = 0.06f;
		default.DamageResistancePerLevel = 0.02f;
		default.AttackSpeedPerLevel = 0.02f;
		default.DamagePerNearbyEnemy = 0.08f;
		default.ResistancePerNearbyEnemy = 0.05f;
		default.MaxNearbyEnemies = 5;
		default.NearbyEnemyRadius = 500.0f;
		default.StumbleImmunityThreshold = 3;
		default.MaxBonusThreshold = 5;
		default.RiotMovementSpeedBonus = 0.30f;
		default.RiotAttackSpeedBonus = 0.20f;
		default.RiotLinger = 3.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// PASSIVE BONUSES (Always Active, Levels 1-20)
// ===================================================================

// Passive 1: Base melee damage per level (all melee damage)
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	local int NearbyCount;
	local float BonusDamage;
	
	// Only apply to melee damage
	if (!IsMeleeDamageType(DamageType)) return;
	
	// Passive bonus: Always active for all melee attacks
	InDamage += Round(float(DefaultDamage) * default.MeleeDamagePerLevel * upgLevel);
	
	// Level 10+: Additional damage based on nearby enemies
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && DamageInstigator != None && DamageInstigator.Pawn != None)
	{
		RiotHelper = GetHelper(KFPawn(DamageInstigator.Pawn));
		if (RiotHelper != None)
		{
			NearbyCount = RiotHelper.GetNearbyEnemyCount();
			
			// Calculate damage bonus from nearby enemies
			BonusDamage = float(DefaultDamage) * default.DamagePerNearbyEnemy * float(NearbyCount);
			InDamage += Round(BonusDamage);
		}
	}
}

// Passive 2: Base damage resistance per level
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
	KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy,
	optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	local int NearbyCount;
	local float ResistanceBonus;
	
	// Passive bonus: Always active
	InDamage = Round(float(InDamage) * (1.0f - (default.DamageResistancePerLevel * upgLevel)));
	
	// Level 10+: Additional resistance based on nearby enemies
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && OwnerPawn != None)
	{
		RiotHelper = GetHelper(OwnerPawn);
		if (RiotHelper != None)
		{
			NearbyCount = RiotHelper.GetNearbyEnemyCount();
			
			// Calculate resistance bonus from nearby enemies
			ResistanceBonus = default.ResistancePerNearbyEnemy * float(NearbyCount);
			InDamage = Round(float(InDamage) * (1.0f - ResistanceBonus));
		}
	}
}

// Passive 3: Base attack speed per level
static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	local KFPawn OwnerPawn;
	local int NearbyCount;
	
	// Passive bonus: Always active
	InDuration = InDuration * (1.0f - (default.AttackSpeedPerLevel * upgLevel));
	
	// Level 20: Additional attack speed when at max threshold
	if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level && KFW != None && KFW.Instigator != None)
	{
		OwnerPawn = KFPawn(KFW.Instigator);
		if (OwnerPawn != None)
		{
			RiotHelper = GetHelper(OwnerPawn);
			if (RiotHelper != None)
			{
				NearbyCount = RiotHelper.GetNearbyEnemyCount();
				
				// Bonus attack speed when surrounded by 5+ enemies
				if (NearbyCount >= default.MaxBonusThreshold)
				{
					InDuration = InDuration / (1.0f + default.RiotAttackSpeedBonus);
				}
			}
		}
	}
}

// ===================================================================
// CONDITIONAL BONUSES (Milestones)
// ===================================================================

// Level 20: Stumble immunity when surrounded
static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower, int upgLevel,
	optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier,
	optional byte BodyPart, optional KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	local int NearbyCount;
	
	if (upgLevel < class'DKConfig_Capstone'.default.Capstone_Rank2Level) return;
	
	if (OwnerPawn != None)
	{
		RiotHelper = GetHelper(OwnerPawn);
		if (RiotHelper != None)
		{
			NearbyCount = RiotHelper.GetNearbyEnemyCount();
			
			// Immune to stumble when surrounded by 3+ enemies
			if (NearbyCount >= default.StumbleImmunityThreshold)
			{
				InStumblePower = 0.0f;
			}
		}
	}
}

// Level 20: Movement speed bonus when at max threshold
static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	local int NearbyCount;
	
	if (upgLevel < class'DKConfig_Capstone'.default.Capstone_Rank2Level) return;
	
	if (OwnerPawn != None)
	{
		RiotHelper = GetHelper(OwnerPawn);
		if (RiotHelper != None)
		{
			NearbyCount = RiotHelper.GetNearbyEnemyCount();
			
			// Bonus movement speed when surrounded by 5+ enemies.
			// Multiply by DefaultSpeed so the bonus is meaningful in absolute
			// units (every other speed perk follows this pattern). Old code
			// did `InSpeed += default.RiotMovementSpeedBonus` which added
			// 0.30 to a value in the hundreds — effectively no bonus.
			if (NearbyCount >= default.MaxBonusThreshold)
			{
				InSpeed += DefaultSpeed * default.RiotMovementSpeedBonus;
			}
		}
	}
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	
	if (OwnerPawn == None || OwnerPawn.Role != ROLE_Authority)
		return;
	
	RiotHelper = GetHelper(OwnerPawn);
	if (RiotHelper == None)
	{
		RiotHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Riot_Helper', OwnerPawn);
		if (RiotHelper != None)
		{
			RiotHelper.Initialize(upgLevel, OwnerPawn);
		}
	}
	else
	{
		// Update level if it changed
		RiotHelper.UpgradeLevel = upgLevel;
	}
}

static function DKUpgrade_Perk_Riot_Helper GetHelper(KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	
	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Riot_Helper', RiotHelper)
		{
			return RiotHelper;
		}
	}
	
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Riot_Helper RiotHelper;
	
	RiotHelper = GetHelper(KFPawn(OwnerPawn));
	if (RiotHelper != None)
	{
		RiotHelper.Destroy();
	}
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

static simulated function Texture2D GetUpgradeIcon(int index)
{
	if (index < 0)
		return default.UpgradeIcon[0];
	else if (index < default.UpgradeIcon.length)
		return default.UpgradeIcon[index];
	else
		return default.UpgradeIcon[default.UpgradeIcon.length - 1];
}

defaultproperties
{
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Riot]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Riot"
    LocalizeDescriptionLineCount=4

	// Passive bonuses per level
	
	// Level 10 "In the Thick of It"
	
	// Level 20 "Riot Control"
	
	UpgradeName="Riot"
	
	// Color-coded descriptions
	UpgradeDescription(0)="<font color=\"#FF4500\">Brawler's Edge:</font> <font color=\"#FFFFFF\">+6%</font> <font color=\"#FFB347\">Melee Damage</font>, <font color=\"#FFFFFF\">+2%</font> <font color=\"#FFB347\">Damage Resistance</font>, and <font color=\"#FFFFFF\">+2%</font> <font color=\"#FFB347\">Attack Speed</font> per level"
	UpgradeDescription(1)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">In the Thick of It</font> - Each enemy within <font color=\"#FFFFFF\">5m</font> grants <font color=\"#FFFFFF\">+8%</font> Melee Damage and <font color=\"#FFFFFF\">+5%</font> Damage Resistance (cap <font color=\"#FFFFFF\">5</font> enemies)"
	UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Riot Control</font> - With <font color=\"#FFFFFF\">3+</font> nearby enemies: <font color=\"#FFB347\">Stumble Immunity</font>. With <font color=\"#FFFFFF\">5+</font>: <font color=\"#FFFFFF\">+30%</font> Movement Speed and <font color=\"#FFFFFF\">+20%</font> Attack Speed"
	UpgradeDescription(3)="Crowd bonuses linger for <font color=\"#FFFFFF\">3 seconds</font> after enemies leave range"
	
	// 21 Icons (Rank_0 through Rank_20)
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Riot_Legacy_Rank_5'

	Name="Default__DKUpgrade_Perk_Riot"
}