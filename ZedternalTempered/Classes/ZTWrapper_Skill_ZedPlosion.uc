// Wrapper for ZedternalReborn.WMUpgrade_Skill_ZedPlosion
class ZTWrapper_Skill_ZedPlosion extends WMUpgrade_Skill_ZedPlosion config(ZedternalUnlimited);

var config array<float> Cfg_Chance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Chance[0] = 0.2f;
		default.Cfg_Chance[1] = 0.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Chance.Length = 2;
		default.Cfg_Chance[0] = 0.200000f;
		default.Cfg_Chance[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function bool ShouldShrapnel(int upgLevel)
{
	return fRand() <= default.Cfg_Chance[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_ZedPlosion"
}
