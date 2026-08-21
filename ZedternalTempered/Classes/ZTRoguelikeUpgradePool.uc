/**
 * ZTRoguelikeUpgradePool
 * Static container for all roguelike upgrade definitions.
 * All upgrade data is stored in defaultproperties for easy expansion.
 *
 * To add new upgrades: Simply add entries to the appropriate array in defaultproperties.
 *
 * Part of the Roguelike Character Upgrade System for Zedternal Reborn.
 */
class ZTRoguelikeUpgradePool extends Object;

//=============================================================================
// UPGRADE POOL ARRAYS
//=============================================================================

/** Universal upgrades - available to all players */
var array<RoguelikeUpgradeData> UniversalUpgrades;

/** Tree-specific upgrades - indexed by ERoguelikeTree */
var array<RoguelikeUpgradeData> EldritchTreeUpgrades;
var array<RoguelikeUpgradeData> MythicalTreeUpgrades;
var array<RoguelikeUpgradeData> HauntedTreeUpgrades;
var array<RoguelikeUpgradeData> UrbanLegendTreeUpgrades;
var array<RoguelikeUpgradeData> MonsterTreeUpgrades;

/** Character-specific Unique upgrades - indexed by character ID within tree */
var array<RoguelikeUpgradeData> EldritchCharacterUniques;

//=============================================================================
// POOL ACCESS FUNCTIONS
//=============================================================================

/** Get all Universal upgrades */
static function array<RoguelikeUpgradeData> GetUniversalUpgrades()
{
	return default.UniversalUpgrades;
}

/** Get tree-specific upgrades for a given tree */
static function array<RoguelikeUpgradeData> GetTreeUpgrades(ERoguelikeTree Tree)
{
	switch (Tree)
	{
		case RLT_Eldritch:
			return default.EldritchTreeUpgrades;
		case RLT_Mythical:
			return default.MythicalTreeUpgrades;
		case RLT_Haunted:
			return default.HauntedTreeUpgrades;
		case RLT_UrbanLegend:
			return default.UrbanLegendTreeUpgrades;
		case RLT_Monster:
			return default.MonsterTreeUpgrades;
		default:
			return default.UniversalUpgrades; // Fallback
	}
}

/** Get character-specific Unique upgrade for a character */
static function bool GetCharacterUnique(ERoguelikeTree Tree, int CharacterIndex, out RoguelikeUpgradeData OutUpgrade)
{
	local array<RoguelikeUpgradeData> CharUniques;
	local int i;

	switch (Tree)
	{
		case RLT_Eldritch:
			CharUniques = default.EldritchCharacterUniques;
			break;
		// Add more trees here as they're implemented
		default:
			return false;
	}

	for (i = 0; i < CharUniques.Length; i++)
	{
		if (CharUniques[i].CharacterRequirement == CharacterIndex)
		{
			OutUpgrade = CharUniques[i];
			return true;
		}
	}

	return false;
}

/** Find an upgrade by ID across all pools */
static function bool FindUpgradeByID(string UpgradeID, out RoguelikeUpgradeData OutUpgrade)
{
	local int i;

	// Search Universal
	for (i = 0; i < default.UniversalUpgrades.Length; i++)
	{
		if (default.UniversalUpgrades[i].UpgradeID == UpgradeID)
		{
			OutUpgrade = default.UniversalUpgrades[i];
			return true;
		}
	}

	// Search Eldritch Tree
	for (i = 0; i < default.EldritchTreeUpgrades.Length; i++)
	{
		if (default.EldritchTreeUpgrades[i].UpgradeID == UpgradeID)
		{
			OutUpgrade = default.EldritchTreeUpgrades[i];
			return true;
		}
	}

	// Search Eldritch Character Uniques
	for (i = 0; i < default.EldritchCharacterUniques.Length; i++)
	{
		if (default.EldritchCharacterUniques[i].UpgradeID == UpgradeID)
		{
			OutUpgrade = default.EldritchCharacterUniques[i];
			return true;
		}
	}

	// Add more tree searches as they're implemented

	return false;
}

/** Get all upgrades of a specific rarity from a pool */
static function array<RoguelikeUpgradeData> FilterByRarity(array<RoguelikeUpgradeData> Pool, ERoguelikeRarity Rarity)
{
	local array<RoguelikeUpgradeData> Result;
	local int i;

	for (i = 0; i < Pool.Length; i++)
	{
		if (Pool[i].Rarity == Rarity)
		{
			Result.AddItem(Pool[i]);
		}
	}

	return Result;
}

/** Build eligible upgrade pool for a player based on their tree/character */
static function array<RoguelikeUpgradeData> BuildEligiblePool(
	ERoguelikeTree PlayerTree,
	int PlayerCharacterIndex,
	ERoguelikeRarity TargetRarity,
	bool bHasCharacterUnique)
{
	local array<RoguelikeUpgradeData> Result;
	local array<RoguelikeUpgradeData> TreeUpgrades;
	local RoguelikeUpgradeData CharUnique;
	local int i;

	`log("[DK_ROGUELIKE] BuildEligiblePool: Tree=" $ int(PlayerTree)
		$ " Char=" $ PlayerCharacterIndex
		$ " Rarity=" $ int(TargetRarity)
		$ " HasUnique=" $ bHasCharacterUnique);

	// Add Universal upgrades of target rarity
	for (i = 0; i < default.UniversalUpgrades.Length; i++)
	{
		if (default.UniversalUpgrades[i].Rarity == TargetRarity)
		{
			// Skip Universal Uniques if player already has one? No - Universal Uniques are separate
			Result.AddItem(default.UniversalUpgrades[i]);
		}
	}

	// Add Tree upgrades of target rarity
	TreeUpgrades = GetTreeUpgrades(PlayerTree);
	for (i = 0; i < TreeUpgrades.Length; i++)
	{
		if (TreeUpgrades[i].Rarity == TargetRarity)
		{
			Result.AddItem(TreeUpgrades[i]);
		}
	}

	// For Unique rarity: Add character-specific Unique (if player doesn't have it yet)
	if (TargetRarity == RLR_Unique && !bHasCharacterUnique)
	{
		if (GetCharacterUnique(PlayerTree, PlayerCharacterIndex, CharUnique))
		{
			Result.AddItem(CharUnique);
		}
	}

	`log("[DK_ROGUELIKE] BuildEligiblePool: Found " $ Result.Length $ " eligible upgrades");

	return Result;
}

defaultproperties
{
	//=========================================================================
	// UNIVERSAL UPGRADES
	//=========================================================================

	// === COMMON (45%) ===
	UniversalUpgrades.Add((UpgradeID="UNIV_C_HEALTH", DisplayName="Toughness", Description="+5 Max Health", Rarity=RLR_Common, PoolType=RLPT_Universal, StatType=RLST_MaxHealth, StatValue=5.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_C_ARMOR", DisplayName="Thick Skin", Description="+5 Max Armor", Rarity=RLR_Common, PoolType=RLPT_Universal, StatType=RLST_MaxArmor, StatValue=5.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_C_SPEED", DisplayName="Quick Feet", Description="+3% Movement Speed", Rarity=RLR_Common, PoolType=RLPT_Universal, StatType=RLST_MovementSpeed, StatValue=0.03, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_C_RELOAD", DisplayName="Steady Hands", Description="+5% Reload Speed", Rarity=RLR_Common, PoolType=RLPT_Universal, StatType=RLST_ReloadSpeed, StatValue=0.05, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_C_AMMO", DisplayName="Ammo Reserves", Description="+5% Ammo Capacity", Rarity=RLR_Common, PoolType=RLPT_Universal, StatType=RLST_AmmoCapacity, StatValue=0.05, bIsPercentage=true))

	// === UNCOMMON (25%) ===
	UniversalUpgrades.Add((UpgradeID="UNIV_U_HEALTH", DisplayName="Vitality", Description="+10 Max Health", Rarity=RLR_Uncommon, PoolType=RLPT_Universal, StatType=RLST_MaxHealth, StatValue=10.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_U_ARMOR", DisplayName="Reinforced", Description="+10 Max Armor", Rarity=RLR_Uncommon, PoolType=RLPT_Universal, StatType=RLST_MaxArmor, StatValue=10.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_U_SPEED", DisplayName="Fleet Footed", Description="+5% Movement Speed", Rarity=RLR_Uncommon, PoolType=RLPT_Universal, StatType=RLST_MovementSpeed, StatValue=0.05, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_U_RELOAD", DisplayName="Fast Hands", Description="+10% Reload Speed", Rarity=RLR_Uncommon, PoolType=RLPT_Universal, StatType=RLST_ReloadSpeed, StatValue=0.10, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_U_AMMO", DisplayName="Deep Pockets", Description="+10% Ammo Capacity", Rarity=RLR_Uncommon, PoolType=RLPT_Universal, StatType=RLST_AmmoCapacity, StatValue=0.10, bIsPercentage=true))

	// === RARE (15%) ===
	UniversalUpgrades.Add((UpgradeID="UNIV_R_HEALTH", DisplayName="Fortitude", Description="+15 Max Health", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_MaxHealth, StatValue=15.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_ARMOR", DisplayName="Hardened", Description="+15 Max Armor", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_MaxArmor, StatValue=15.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_SPEED", DisplayName="Sprinter", Description="+8% Movement Speed", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_MovementSpeed, StatValue=0.08, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_RELOAD", DisplayName="Rapid Reload", Description="+15% Reload Speed", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_ReloadSpeed, StatValue=0.15, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_AMMO", DisplayName="Stockpile", Description="+15% Ammo Capacity", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_AmmoCapacity, StatValue=0.15, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_DAMAGE", DisplayName="Sharpened", Description="+5% Damage Dealt", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_DamageDealt, StatValue=0.05, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_R_RESIST", DisplayName="Resilient", Description="-3% Damage Taken", Rarity=RLR_Rare, PoolType=RLPT_Universal, StatType=RLST_DamageResist, StatValue=0.03, bIsPercentage=true))

	// === EPIC (10%) ===
	UniversalUpgrades.Add((UpgradeID="UNIV_E_HEALTH", DisplayName="Vigor", Description="+25 Max Health", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_MaxHealth, StatValue=25.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_ARMOR", DisplayName="Armored", Description="+25 Max Armor", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_MaxArmor, StatValue=25.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_SPEED", DisplayName="Wind Runner", Description="+10% Movement Speed", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_MovementSpeed, StatValue=0.10, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_RELOAD", DisplayName="Lightning Hands", Description="+20% Reload Speed", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_ReloadSpeed, StatValue=0.20, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_AMMO", DisplayName="Arsenal", Description="+20% Ammo Capacity", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_AmmoCapacity, StatValue=0.20, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_DAMAGE", DisplayName="Lethal", Description="+8% Damage Dealt", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_DamageDealt, StatValue=0.08, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_E_RESIST", DisplayName="Stalwart", Description="-4% Damage Taken", Rarity=RLR_Epic, PoolType=RLPT_Universal, StatType=RLST_DamageResist, StatValue=0.04, bIsPercentage=true))

	// === LEGENDARY (4%) ===
	UniversalUpgrades.Add((UpgradeID="UNIV_L_HEALTH", DisplayName="Titan's Constitution", Description="+40 Max Health", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_MaxHealth, StatValue=40.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_ARMOR", DisplayName="Living Fortress", Description="+40 Max Armor", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_MaxArmor, StatValue=40.0, bIsPercentage=false))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_SPEED", DisplayName="Blur", Description="+15% Movement Speed", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_MovementSpeed, StatValue=0.15, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_RELOAD", DisplayName="Instant Load", Description="+30% Reload Speed", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_ReloadSpeed, StatValue=0.30, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_AMMO", DisplayName="Armory", Description="+30% Ammo Capacity", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_AmmoCapacity, StatValue=0.30, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_DAMAGE", DisplayName="Devastating", Description="+12% Damage Dealt", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_DamageDealt, StatValue=0.12, bIsPercentage=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_L_RESIST", DisplayName="Unbreakable", Description="-6% Damage Taken", Rarity=RLR_Legendary, PoolType=RLPT_Universal, StatType=RLST_DamageResist, StatValue=0.06, bIsPercentage=true))

	// === UNIQUE (1%) - Universal Mini-Passives ===
	UniversalUpgrades.Add((UpgradeID="UNIV_X_SECONDWIND", DisplayName="Second Wind", Description="Below 25% HP: 50% damage resist for 3s (30s cooldown)", Rarity=RLR_Unique, PoolType=RLPT_Universal, StatType=RLST_Special, bIsPassiveEffect=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_X_DOSHMAGNET", DisplayName="Dosh Magnet", Description="+50% dosh pickup radius, +10% dosh from kills", Rarity=RLR_Unique, PoolType=RLPT_Universal, StatType=RLST_Special, bIsPassiveEffect=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_X_ADRENALINE", DisplayName="Adrenaline Rush", Description="Kills grant +10% move speed for 2s (stacks 3x)", Rarity=RLR_Unique, PoolType=RLPT_Universal, StatType=RLST_Special, bIsPassiveEffect=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_X_LASTSTAND", DisplayName="Last Stand", Description="+25% damage when below 50% health", Rarity=RLR_Unique, PoolType=RLPT_Universal, StatType=RLST_Special, bIsPassiveEffect=true))
	UniversalUpgrades.Add((UpgradeID="UNIV_X_VAMPIRIC", DisplayName="Vampiric Rounds", Description="1% of damage dealt returned as health", Rarity=RLR_Unique, PoolType=RLPT_Universal, StatType=RLST_Special, bIsPassiveEffect=true))

	//=========================================================================
	// ELDRITCH TREE UPGRADES
	//=========================================================================

	// === COMMON (45%) ===
	EldritchTreeUpgrades.Add((UpgradeID="ELD_C_LARGEZED", DisplayName="Void Touched", Description="+3% damage vs Large Zeds", Rarity=RLR_Common, PoolType=RLPT_Tree, TreeRequirement=0, StatType=RLST_LargeZedDamage, StatValue=0.03, bIsPercentage=true))

	// === UNCOMMON (25%) ===
	EldritchTreeUpgrades.Add((UpgradeID="ELD_U_LARGEZED", DisplayName="Abyssal Affinity", Description="+5% damage vs Large Zeds", Rarity=RLR_Uncommon, PoolType=RLPT_Tree, TreeRequirement=0, StatType=RLST_LargeZedDamage, StatValue=0.05, bIsPercentage=true))

	// === RARE (15%) ===
	EldritchTreeUpgrades.Add((UpgradeID="ELD_R_LARGEZED", DisplayName="Eldritch Insight", Description="+8% damage vs Large Zeds", Rarity=RLR_Rare, PoolType=RLPT_Tree, TreeRequirement=0, StatType=RLST_LargeZedDamage, StatValue=0.08, bIsPercentage=true))

	// === EPIC (10%) ===
	EldritchTreeUpgrades.Add((UpgradeID="ELD_E_LARGEZED", DisplayName="Cosmic Horror", Description="+12% damage vs Large Zeds", Rarity=RLR_Epic, PoolType=RLPT_Tree, TreeRequirement=0, StatType=RLST_LargeZedDamage, StatValue=0.12, bIsPercentage=true))

	// === LEGENDARY (4%) ===
	EldritchTreeUpgrades.Add((UpgradeID="ELD_L_LARGEZED", DisplayName="Beyond Comprehension", Description="+18% damage vs Large Zeds", Rarity=RLR_Legendary, PoolType=RLPT_Tree, TreeRequirement=0, StatType=RLST_LargeZedDamage, StatValue=0.18, bIsPercentage=true))

	//=========================================================================
	// ELDRITCH CHARACTER UNIQUE UPGRADES (1%)
	// CharacterRequirement corresponds to character index (0-9)
	//=========================================================================

	// MythicalOne (Index 0): +2% damage per 50 kills (upgraded from +1% per 100 kills)
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_MYTHICALONE", DisplayName="Void Mastery", Description="Now gain +2% damage per 50 kills (was +1% per 100)", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=0, StatType=RLST_Special, bIsPassiveEffect=true))

	// ForgottenOne (Index 1): Cap raised to 150% (from 20%)
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_FORGOTTENONE", DisplayName="Eternal Oblivion", Description="Damage bonus cap raised to 150% (was 20%)", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=1, StatType=RLST_Special, bIsPassiveEffect=true))

	// AllSeeingOne (Index 2): Every 3rd headshot deals 3x damage
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_ALLSEEINGONE", DisplayName="Omniscience", Description="Every 3rd headshot deals 3x damage (no setup required)", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=2, StatType=RLST_Special, bIsPassiveEffect=true))

	// ConstructedOne (Index 3): Heal 5 HP per kill
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_CONSTRUCTEDONE", DisplayName="Living Harvest", Description="Now heal 5 HP per kill", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=3, StatType=RLST_Special, bIsPassiveEffect=true))

	// ElusiveOne (Index 4): 50% chance to ignore any damage
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_ELUSIVEONE", DisplayName="Untouchable", Description="50% chance to completely ignore any incoming damage", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=4, StatType=RLST_Special, bIsPassiveEffect=true))

	// ForcefulOne (Index 5): 3x damage for 15s every 60s
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_FORCEFULONE", DisplayName="Endless Fury", Description="Every 60s, deal 3x damage for 15 seconds", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=5, StatType=RLST_Special, bIsPassiveEffect=true))

	// GrinningOne (Index 6): Cap raised to +200%/-100%
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_GRINNINGONE", DisplayName="Complete Insanity", Description="Stack cap raised to +200% damage dealt / -100% damage taken", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=6, StatType=RLST_Special, bIsPassiveEffect=true))

	// LoomingOne (Index 7): No cap, unlimited scaling
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_LOOMINGONE", DisplayName="Infinite Dread", Description="Large zed damage bonus no longer capped (was 25%)", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=7, StatType=RLST_Special, bIsPassiveEffect=true))

	// ShapelessOne (Index 8): 95% resist to last damage type
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_SHAPELESSONE", DisplayName="True Formlessness", Description="95% damage resistance to last damage type taken (was 30%)", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=8, StatType=RLST_Special, bIsPassiveEffect=true))

	// SunkenOne (Index 9): 10s damage immunity every 60s
	EldritchCharacterUniques.Add((UpgradeID="ELD_X_SUNKENONE", DisplayName="Abyssal Sanctuary", Description="Every 60s, become immune to all damage for 10 seconds", Rarity=RLR_Unique, PoolType=RLPT_Character, TreeRequirement=0, CharacterRequirement=9, StatType=RLST_Special, bIsPassiveEffect=true))

	Name="Default__ZTRoguelikeUpgradePool"
}
