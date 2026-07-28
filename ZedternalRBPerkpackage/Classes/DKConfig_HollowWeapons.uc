class DKConfig_HollowWeapons extends Config_Common
	config(ZedternalUnlimited);

// ===================================================================
// HOLLOW WEAPONS CONFIG
//
// Server-side toggle for the Hollow weapon variant system.
// When disabled:
//   - Hollow weapons are not registered in the trader
//   - Trial challenge cards are not shown on HUD
//   - Hollow stat bonuses are not applied
//   - The Hollow perk itself still functions (base stats)
//
// INI: KFZedternalUnlimited.ini
// ===================================================================

var config int MODEVERSION;

// Master toggle: set to False to disable all Hollow weapon variants
var config bool HollowWeapons_bEnable;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HollowWeapons_bEnable = True;
	}

	if (default.MODEVERSION < 1)
	{
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	// Bool only — no range validation needed
	`log("[DK_HOLLOW] Config: HollowWeapons_bEnable=" $ default.HollowWeapons_bEnable);
}

/** Check if Hollow weapon variants are enabled. */
static function bool IsEnabled()
{
	return default.HollowWeapons_bEnable;
}

defaultproperties
{
	Name="Default__DKConfig_HollowWeapons"
}
