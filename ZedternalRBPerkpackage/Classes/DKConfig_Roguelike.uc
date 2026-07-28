// ===================================================================
// DKConfig_Roguelike - Server-side roguelike system configuration
//
// Controls the roguelike upgrade selection system.
// Saved to KFZedternalUnlimited.ini
// ===================================================================
class DKConfig_Roguelike extends Object
	config(ZedternalUnlimited);

// Master on/off switch for the entire roguelike upgrade system.
// True (default) = system active. False = no upgrade popups and no roguelike
// bonuses are ever granted (the manager is not even spawned). Use this to
// disable roguelike for balance without touching individual values.
var config bool bEnableRoguelike;

// How often the upgrade selection popup appears (every N waves)
// Default: 3 (waves 3, 6, 9, 12...)
// Set to 1 for every wave, 5 for every 5th wave, etc.
var config int UpgradeWaveInterval;

// Late-joiner catch-up: when True, a player who joins mid-game is granted the
// roguelike upgrade selections they missed (one per interval already elapsed),
// presented back-to-back at the next trader. Opt-in; default False.
var config bool bCatchUpLateJoiners;

// Optional cap on how many catch-up selections a late joiner can receive.
// 0 = unlimited (grant exactly what was missed).
var config int CatchUpMaxSelections;

var config int MODEVERSION;

static function UpdateConfig()
{
	local bool bDirty;

	bDirty = False;

	if (default.MODEVERSION < 1)
	{
		default.UpgradeWaveInterval = 3;

		default.MODEVERSION = 1;
		bDirty = True;
	}

	if (default.MODEVERSION < 2)
	{
		// Master roguelike toggle added in v2 (defaults ON = prior behavior)
		default.bEnableRoguelike = True;

		default.MODEVERSION = 2;
		bDirty = True;
	}

	if (default.MODEVERSION < 3)
	{
		// Late-joiner catch-up added in v3 (defaults OFF = prior behavior)
		default.bCatchUpLateJoiners = False;
		default.CatchUpMaxSelections = 0;

		default.MODEVERSION = 3;
		bDirty = True;
	}

	if (bDirty)
		static.StaticSaveConfig();
}

static function CheckBasicConfigValues()
{
	if (default.UpgradeWaveInterval < 1)
	{
		`log("[DK_ROGUELIKE] WARNING: UpgradeWaveInterval < 1, clamping to 1");
		default.UpgradeWaveInterval = 1;
	}
	if (default.UpgradeWaveInterval > 100)
	{
		`log("[DK_ROGUELIKE] WARNING: UpgradeWaveInterval > 100, clamping to 100");
		default.UpgradeWaveInterval = 100;
	}
	if (default.CatchUpMaxSelections < 0)
	{
		`log("[DK_ROGUELIKE] WARNING: CatchUpMaxSelections < 0, clamping to 0 (unlimited)");
		default.CatchUpMaxSelections = 0;
	}
	`log("[DK_ROGUELIKE] Config: Enabled=" $ default.bEnableRoguelike $ " Interval=" $ default.UpgradeWaveInterval $ " CatchUp=" $ default.bCatchUpLateJoiners $ " CatchUpMax=" $ default.CatchUpMaxSelections);
}

static function int GetUpgradeWaveInterval()
{
	if (default.UpgradeWaveInterval < 1)
		return 3;
	return default.UpgradeWaveInterval;
}

static function bool IsRoguelikeEnabled()
{
	return default.bEnableRoguelike;
}

static function bool IsCatchUpEnabled()
{
	return default.bCatchUpLateJoiners;
}

static function int GetCatchUpMaxSelections()
{
	if (default.CatchUpMaxSelections < 0)
		return 0;
	return default.CatchUpMaxSelections;
}

defaultproperties
{
	Name="Default__DKConfig_Roguelike"
}
