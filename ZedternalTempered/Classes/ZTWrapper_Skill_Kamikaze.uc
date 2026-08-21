// Wrapper for ZedternalReborn.WMUpgrade_Skill_Kamikaze
class ZTWrapper_Skill_Kamikaze extends WMUpgrade_Skill_Kamikaze config(ZedternalUnlimited);

var config float Cfg_DamageDeluxe;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageDeluxe = 0.25f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_DamageDeluxe = 0.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	if (upgLevel > 1)
		damageFactor += default.Cfg_DamageDeluxe;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Kamikaze"
}
