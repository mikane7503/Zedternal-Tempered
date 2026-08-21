// ===================================================================
// ZTConfig_PerkLimit - Limits how many DIFFERENT perks a player can own
// Lives in KFZedternalUnlimited.ini under
//   [ZedternalTempered.ZTConfig_PerkLimit]
//
// Player_MaxDifferentPerks:
//   0  = disabled (no limit, default behavior)
//   >0 = maximum number of distinct perks a player can purchase.
//         Once the cap is reached, the player can still upgrade
//         existing perks to higher levels, but cannot buy new ones.
//   Example: 5 means each player can own at most 5 different perks.
//
// Player_ProgressivePerkUnlock:
//   False = flat cap (default behavior).
//   True  = the cap GROWS by one each time the player takes every currently
//           owned perk to its max level, so a new perk slot opens only after
//           the current ones are fully leveled (5 maxed -> 6th unlocks, 6th
//           maxed -> 7th unlocks, etc). Still bounded by the unlocked random
//           pool (Config_PerkUpgradeOptions.PerkUpgrade_AvailablePerks).
//           Requires Player_MaxDifferentPerks > 0 to have any effect.
// ===================================================================
class ZTConfig_PerkLimit extends Config_Common config(ZedternalUnlimited);

var config int MODEVERSION;

var config int Player_MaxDifferentPerks;
var config bool Player_ProgressivePerkUnlock;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Player_MaxDifferentPerks = 0;
	}

	if (default.MODEVERSION < 2)
	{
		default.Player_ProgressivePerkUnlock = false;
	}

	if (default.MODEVERSION < 2)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Player_MaxDifferentPerks = 0;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	if (default.Player_MaxDifferentPerks < 0)
	{
		LogBadConfigMessage("Player_MaxDifferentPerks",
			string(default.Player_MaxDifferentPerks),
			"0", "disabled, no perk limit", "value >= 0");
		default.Player_MaxDifferentPerks = 0;
	}
}

defaultproperties
{
	Name="Default__ZTConfig_PerkLimit"
}
