// Wrapper for ZedternalReborn.WMUpgrade_Skill_RapidAssault
class ZTWrapper_Skill_RapidAssault extends WMUpgrade_Skill_RapidAssault config(ZedternalUnlimited);

var config array<float> Cfg_RateOfFire;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_RateOfFire[0] = 0.2f;
		default.Cfg_RateOfFire[1] = 0.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_RateOfFire.Length = 2;
		default.Cfg_RateOfFire[0] = 0.200000f;
		default.Cfg_RateOfFire[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local float Fb_RateOfFire;

	if (default.Cfg_RateOfFire.Length > 0 && default.Cfg_RateOfFire[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_RateOfFire.Length > 1)
			Fb_RateOfFire = default.Cfg_RateOfFire[1];
		else
			Fb_RateOfFire = default.Cfg_RateOfFire[0];
	}
	else
	{
		if (upgLevel > 1 && default.RateOfFire.Length > 1)
			Fb_RateOfFire = default.RateOfFire[1];
		else
			Fb_RateOfFire = default.RateOfFire[0];
	}
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + Fb_RateOfFire);
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	local float Fb_RateOfFire;

	if (default.Cfg_RateOfFire.Length > 0 && default.Cfg_RateOfFire[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_RateOfFire.Length > 1)
			Fb_RateOfFire = default.Cfg_RateOfFire[1];
		else
			Fb_RateOfFire = default.Cfg_RateOfFire[0];
	}
	else
	{
		if (upgLevel > 1 && default.RateOfFire.Length > 1)
			Fb_RateOfFire = default.RateOfFire[1];
		else
			Fb_RateOfFire = default.RateOfFire[0];
	}
	durationFactor = 1.0f / (1.0f / durationFactor + Fb_RateOfFire);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_RapidAssault"
}
