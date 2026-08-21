// Wrapper for ZedternalReborn.WMUpgrade_Skill_Dreadnaught
class ZTWrapper_Skill_Dreadnaught extends WMUpgrade_Skill_Dreadnaught config(ZedternalUnlimited);

var config array<float> Cfg_Health;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health[0] = 0.25f;
		default.Cfg_Health[1] = 0.6f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Health.Length = 2;
		default.Cfg_Health[0] = 0.250000f;
		default.Cfg_Health[1] = 0.600000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * default.Cfg_Health[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Dreadnaught"
}
