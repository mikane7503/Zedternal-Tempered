// ===================================================================
// DKConfig_PlayerSpeed - Server-side player speed configuration
// Lives in KFZedternalUnlimited.ini under
//   [ZedternalRBPerkpackage.DKConfig_PlayerSpeed]
//
// Both settings are disabled by default (0.0 = no effect).
//
// Player_SpeedModifier:
//   Global multiplier applied AFTER all perk/skill/equipment bonuses.
//   0.0 = disabled (no change). 1.2 = 20% faster. 0.8 = 20% slower.
//
// Player_SpeedCap:
//   Hard cap on final GroundSpeed. SprintSpeed is capped proportionally.
//   0.0 = disabled (no cap). KF2 default GroundSpeed is 383.
//   Example: 600.0 limits maximum speed regardless of bonuses.
// ===================================================================
class DKConfig_PlayerSpeed extends Config_Common
	config(ZedternalUnlimited);

var config int MODEVERSION;

var config float Player_SpeedModifier;
var config float Player_SpeedCap;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Player_SpeedModifier = 0.0f;
		default.Player_SpeedCap = 0.0f;
	}

	if (default.MODEVERSION < 1)
	{
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	if (default.Player_SpeedModifier < 0.0f)
	{
		LogBadConfigMessage("Player_SpeedModifier",
			string(default.Player_SpeedModifier),
			"0.0", "disabled, no speed modification", "value >= 0.0");
		default.Player_SpeedModifier = 0.0f;
	}

	if (default.Player_SpeedCap < 0.0f)
	{
		LogBadConfigMessage("Player_SpeedCap",
			string(default.Player_SpeedCap),
			"0.0", "disabled, no speed cap", "value >= 0.0");
		default.Player_SpeedCap = 0.0f;
	}
}

defaultproperties
{
	Name="Default__DKConfig_PlayerSpeed"
}
