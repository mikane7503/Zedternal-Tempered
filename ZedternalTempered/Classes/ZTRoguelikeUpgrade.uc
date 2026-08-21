/**
 * ZTRoguelikeUpgrade
 * Base class containing all roguelike upgrade definitions, enums, and structs.
 * This is a static data container - no instances are created.
 *
 * Part of the Roguelike Character Upgrade System for Zedternal Reborn.
 * UPDATED: Added RequiredPerkName for perk-specific Unique upgrades
 */
class ZTRoguelikeUpgrade extends Object;

//=============================================================================
// ENUMS
//=============================================================================

/** Rarity tiers with associated drop chances */
enum ERoguelikeRarity
{
	RLR_Common,      // 45%
	RLR_Uncommon,    // 25%
	RLR_Rare,        // 15%
	RLR_Epic,        // 10%
	RLR_Legendary,   // 4%
	RLR_Unique       // 1%
};

/** Pool types determine who can receive which upgrades */
enum ERoguelikePoolType
{
	RLPT_Universal,  // Available to all players
	RLPT_Tree,       // Available to players of a specific tree
	RLPT_Character,  // Available only to a specific character (Unique upgrades)
	RLPT_Perk        // Available only to players who own a specific perk
};

/** Stat types that upgrades can modify */
enum ERoguelikeStatType
{
	RLST_None,
	RLST_MaxHealth,
	RLST_MaxArmor,
	RLST_MovementSpeed,
	RLST_ReloadSpeed,
	RLST_AmmoCapacity,
	RLST_DamageDealt,
	RLST_DamageResist,
	RLST_LargeZedDamage,
	RLST_HeadshotDamage,
	RLST_DoshGain,
	RLST_HealAmount,
	RLST_Special       // For Unique passives with custom logic
};

/** Tree identifiers - expandable for future trees */
enum ERoguelikeTree
{
	RLT_None,
	RLT_Eldritch,
	RLT_Mythical,
	RLT_Haunted,
	RLT_UrbanLegend,
	RLT_Monster
	// Add more trees here as needed
};

//=============================================================================
// STRUCTS
//=============================================================================

/** Core upgrade definition */
struct RoguelikeUpgradeData
{
	var string UpgradeID;           // Unique identifier (e.g., "UNIV_C_HEALTH")
	var string DisplayName;         // Shown in UI
	var string Description;         // Tooltip text
	var string IconPath;            // Texture path for icon
	var ERoguelikeRarity Rarity;
	var ERoguelikePoolType PoolType;
	var ERoguelikeTree TreeRequirement;    // Only for Tree/Character pools
	var int CharacterRequirement;          // Character index for Unique upgrades (-1 for none)
	var string RequiredPerkName;           // Perk UpgradeName required (e.g., "Agony") - for RLPT_Perk only
	var ERoguelikeStatType StatType;
	var float StatValue;            // The bonus value (additive)
	var bool bIsPercentage;         // True if StatValue is a percentage modifier
	var bool bIsPassiveEffect;      // True for Unique mini-passives with custom logic

	structdefaultproperties
	{
		UpgradeID=""
		DisplayName="Unknown Upgrade"
		Description="No description"
		IconPath=""
		Rarity=RLR_Common
		PoolType=RLPT_Universal
		TreeRequirement=RLT_None
		CharacterRequirement=-1
		RequiredPerkName=""
		StatType=RLST_None
		StatValue=0.0
		bIsPercentage=false
		bIsPassiveEffect=false
	}
};

/** Player's accumulated upgrade state for a single upgrade type */
struct RoguelikeUpgradeStack
{
	var string UpgradeID;           // Which upgrade this is
	var int StackCount;             // How many times selected (for additive stacking)

	structdefaultproperties
	{
		UpgradeID=""
		StackCount=0
	}
};

/** Complete roguelike state for a player */
struct RoguelikePlayerState
{
	var ERoguelikeTree SelectedTree;
	var int SelectedCharacterIndex;
	var array<RoguelikeUpgradeStack> AcquiredUpgrades;
	var bool bHasCharacterUnique;   // True if player has their character's Unique upgrade
	var int TotalUpgradesSelected;

	structdefaultproperties
	{
		SelectedTree=RLT_None
		SelectedCharacterIndex=-1
		bHasCharacterUnique=false
		TotalUpgradesSelected=0
	}
};

//=============================================================================
// STATIC HELPER FUNCTIONS
//=============================================================================

/** Get rarity name for display */
static function string GetRarityName(ERoguelikeRarity Rarity)
{
	switch (Rarity)
	{
		case RLR_Common:    return "Common";
		case RLR_Uncommon:  return "Uncommon";
		case RLR_Rare:      return "Rare";
		case RLR_Epic:      return "Epic";
		case RLR_Legendary: return "Legendary";
		case RLR_Unique:    return "Unique";
		default:            return "Unknown";
	}
}

/** Get rarity color for UI (returns hex color as int) */
static function int GetRarityColor(ERoguelikeRarity Rarity)
{
	switch (Rarity)
	{
		case RLR_Common:    return 0xFFFFFF; // White
		case RLR_Uncommon:  return 0x1EFF00; // Green
		case RLR_Rare:      return 0x0070DD; // Blue
		case RLR_Epic:      return 0xA335EE; // Purple
		case RLR_Legendary: return 0xFF8000; // Orange
		case RLR_Unique:    return 0xFFD700; // Gold
		default:            return 0xFFFFFF;
	}
}

/** Get rarity color as linear color for Canvas drawing */
static function Color GetRarityLinearColor(ERoguelikeRarity Rarity)
{
	local Color C;

	switch (Rarity)
	{
		case RLR_Common:
			C.R = 255; C.G = 255; C.B = 255; C.A = 255;
			break;
		case RLR_Uncommon:
			C.R = 30; C.G = 255; C.B = 0; C.A = 255;
			break;
		case RLR_Rare:
			C.R = 0; C.G = 112; C.B = 221; C.A = 255;
			break;
		case RLR_Epic:
			C.R = 163; C.G = 53; C.B = 238; C.A = 255;
			break;
		case RLR_Legendary:
			C.R = 255; C.G = 128; C.B = 0; C.A = 255;
			break;
		case RLR_Unique:
			C.R = 255; C.G = 215; C.B = 0; C.A = 255;
			break;
		default:
			C.R = 255; C.G = 255; C.B = 255; C.A = 255;
	}

	return C;
}

/** Get tree name for display */
static function string GetTreeName(ERoguelikeTree Tree)
{
	switch (Tree)
	{
		case RLT_Eldritch:    return "Eldritch";
		case RLT_Mythical:    return "Mythical";
		case RLT_Haunted:     return "Haunted";
		case RLT_UrbanLegend: return "Urban Legend";
		case RLT_Monster:     return "Monster";
		default:              return "None";
	}
}

/** Get stat type name for display */
static function string GetStatTypeName(ERoguelikeStatType StatType)
{
	switch (StatType)
	{
		case RLST_MaxHealth:      return "Max Health";
		case RLST_MaxArmor:       return "Max Armor";
		case RLST_MovementSpeed:  return "Movement Speed";
		case RLST_ReloadSpeed:    return "Reload Speed";
		case RLST_AmmoCapacity:   return "Ammo Capacity";
		case RLST_DamageDealt:    return "Damage Dealt";
		case RLST_DamageResist:   return "Damage Resistance";
		case RLST_LargeZedDamage: return "Large Zed Damage";
		case RLST_HeadshotDamage: return "Headshot Damage";
		case RLST_DoshGain:       return "Dosh Gain";
		case RLST_HealAmount:     return "Healing";
		case RLST_Special:        return "Special";
		default:                  return "None";
	}
}

/** Roll a rarity based on drop chances (45/25/15/10/4/1) */
static function ERoguelikeRarity RollRarity()
{
	local int Roll;

	Roll = Rand(100);

	if (Roll < 45)
		return RLR_Common;      // 0-44 = 45%
	else if (Roll < 70)
		return RLR_Uncommon;    // 45-69 = 25%
	else if (Roll < 85)
		return RLR_Rare;        // 70-84 = 15%
	else if (Roll < 95)
		return RLR_Epic;        // 85-94 = 10%
	else if (Roll < 99)
		return RLR_Legendary;   // 95-98 = 4%
	else
		return RLR_Unique;      // 99 = 1%
}

/** Roll a rarity but exclude Unique (for players with no eligible uniques) */
static function ERoguelikeRarity RollRarityNoUnique()
{
	local int Roll;

	Roll = Rand(100);

	if (Roll < 46)
		return RLR_Common;
	else if (Roll < 71)
		return RLR_Uncommon;
	else if (Roll < 86)
		return RLR_Rare;
	else if (Roll < 96)
		return RLR_Epic;
	else
		return RLR_Legendary;
}

defaultproperties
{
	Name="Default__ZTRoguelikeUpgrade"
}
