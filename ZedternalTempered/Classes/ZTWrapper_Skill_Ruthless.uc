// Wrapper for ZedternalReborn.WMUpgrade_Skill_Ruthless
class ZTWrapper_Skill_Ruthless extends WMUpgrade_Skill_Ruthless config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.4f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.150000f;
		default.Cfg_Damage[1] = 0.400000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor += default.Cfg_Damage[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Ruthless"
}
