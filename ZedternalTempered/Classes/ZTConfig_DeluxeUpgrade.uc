// ===================================================================
// ZTConfig_DeluxeUpgrade - On-demand Deluxe skill upgrade system
//
// Opt-in dosh sink. Lets a player convert an already owned, non-Deluxe
// skill into its Deluxe version for a configurable fee, once the owning
// perk reaches a configurable level. Two modes:
//   Targeted  - the player picks which owned skill to upgrade.
//   Random    - the server rolls a random eligible skill in that perk.
//
// Saved to KFZedternalUnlimited.ini
//   [ZedternalTempered.ZTConfig_DeluxeUpgrade]
// ===================================================================
class ZTConfig_DeluxeUpgrade extends Object config(ZedternalUnlimited);

// Master on/off. False (default) = feature disabled, no upgrade rows shown.
var config bool bEnableDeluxeUpgrade;

// The owning perk must be at least this level before its skills become
// eligible for a Deluxe upgrade.
var config int MinPerkLevel;

// Dosh cost per Deluxe conversion.
var config int UpgradeCost;

// True  = targeted (one row per eligible owned non-Deluxe skill; player picks).
// False = random  (one row per eligible perk; server rolls a skill within it).
var config bool bTargetedSelection;

var config int MODEVERSION;

static function UpdateConfig()
{
	local bool bDirty;

	bDirty = False;

	if (default.MODEVERSION < 1)
	{
		default.bEnableDeluxeUpgrade = False;
		default.MinPerkLevel = 10;
		default.UpgradeCost = 1500;
		default.bTargetedSelection = False;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.MinPerkLevel = 10;
		default.UpgradeCost = 2000;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		bDirty = True;
	}

	if (bDirty)
		static.StaticSaveConfig();
}

static function CheckBasicConfigValues()
{
	if (default.MinPerkLevel < 1)
	{
		`log("[DK_DELUXE] WARNING: MinPerkLevel < 1, clamping to 1");
		default.MinPerkLevel = 1;
	}
	if (default.MinPerkLevel > 255)
	{
		`log("[DK_DELUXE] WARNING: MinPerkLevel > 255, clamping to 255");
		default.MinPerkLevel = 255;
	}
	if (default.UpgradeCost < 0)
	{
		`log("[DK_DELUXE] WARNING: UpgradeCost < 0, clamping to 0");
		default.UpgradeCost = 0;
	}
	`log("[DK_DELUXE] Config: Enabled=" $ default.bEnableDeluxeUpgrade
		$ " MinPerkLevel=" $ default.MinPerkLevel
		$ " UpgradeCost=" $ default.UpgradeCost
		$ " Targeted=" $ default.bTargetedSelection);
}

static function bool IsEnabled()
{
	return default.bEnableDeluxeUpgrade;
}

static function int GetMinPerkLevel()
{
	if (default.MinPerkLevel < 1)
		return 10;
	return default.MinPerkLevel;
}

static function int GetUpgradeCost()
{
	if (default.UpgradeCost < 0)
		return 0;
	return default.UpgradeCost;
}

static function bool IsTargeted()
{
	return default.bTargetedSelection;
}

defaultproperties
{
	Name="Default__ZTConfig_DeluxeUpgrade"
}
