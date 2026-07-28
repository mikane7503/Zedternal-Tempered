// Wrapper for ZedternalReborn.WMUpgrade_Skill_Butcher
class DKWrapper_Skill_Butcher extends WMUpgrade_Skill_Butcher
	config(ZedternalUnlimited);

var config array<float> Cfg_MeleeSpeed;
var config array<float> Cfg_RateOfFire;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MeleeSpeed[0] = 0.15f;
		default.Cfg_MeleeSpeed[1] = 0.4f;
		default.Cfg_RateOfFire[0] = 0.15f;
		default.Cfg_RateOfFire[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	local float Fb_MeleeSpeed;

	if (default.Cfg_MeleeSpeed.Length > 0 && default.Cfg_MeleeSpeed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MeleeSpeed.Length > 1)
			Fb_MeleeSpeed = default.Cfg_MeleeSpeed[1];
		else
			Fb_MeleeSpeed = default.Cfg_MeleeSpeed[0];
	}
	else
	{
		if (upgLevel > 1 && default.MeleeSpeed.Length > 1)
			Fb_MeleeSpeed = default.MeleeSpeed[1];
		else
			Fb_MeleeSpeed = default.MeleeSpeed[0];
	}
	durationFactor = 1.0f / (1.0f / durationFactor + Fb_MeleeSpeed);
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

defaultproperties
{
	Name="Default__DKWrapper_Skill_Butcher"
}
