// Wrapper for ZedternalReborn.WMUpgrade_Skill_Strength
class ZTWrapper_Skill_Strength extends WMUpgrade_Skill_Strength config(ZedternalUnlimited);

var config array<int> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 3;
		default.Cfg_Bonus[1] = 8;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Bonus.Length = 2;
		default.Cfg_Bonus[0] = 3;
		default.Cfg_Bonus[1] = 8;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ApplyWeightLimits(out int InWeightLimit, int DefaultWeightLimit, int upgLevel)
{
	InWeightLimit += default.Cfg_Bonus[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Strength"
}
