// Wrapper for ZedternalReborn.WMUpgrade_Skill_Salvo
class ZTWrapper_Skill_Salvo extends WMUpgrade_Skill_Salvo config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.1f;
		default.Cfg_Bonus[1] = 0.25f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Bonus.Length = 2;
		default.Cfg_Bonus[0] = 0.100000f;
		default.Cfg_Bonus[1] = 0.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor += default.Cfg_Bonus[upgLevel - 1];
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local float Fb_Bonus;

	if (default.Cfg_Bonus.Length > 0 && default.Cfg_Bonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Bonus.Length > 1)
			Fb_Bonus = default.Cfg_Bonus[1];
		else
			Fb_Bonus = default.Cfg_Bonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.Bonus.Length > 1)
			Fb_Bonus = default.Bonus[1];
		else
			Fb_Bonus = default.Bonus[0];
	}
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + Fb_Bonus);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Salvo"
}
