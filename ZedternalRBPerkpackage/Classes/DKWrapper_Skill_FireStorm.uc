// Wrapper for ZedternalReborn.WMUpgrade_Skill_FireStorm
class DKWrapper_Skill_FireStorm extends WMUpgrade_Skill_FireStorm
	config(ZedternalUnlimited);

var config array<float> Cfg_MeleeSpeed;
var config array<float> Cfg_FireRate;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MeleeSpeed[0] = 0.15f;
		default.Cfg_MeleeSpeed[1] = 0.4f;
		default.Cfg_FireRate[0] = 0.15f;
		default.Cfg_FireRate[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local float Fb_FireRate;

	if (default.Cfg_FireRate.Length > 0 && default.Cfg_FireRate[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_FireRate.Length > 1)
			Fb_FireRate = default.Cfg_FireRate[1];
		else
			Fb_FireRate = default.Cfg_FireRate[0];
	}
	else
	{
		if (upgLevel > 1 && default.FireRate.Length > 1)
			Fb_FireRate = default.FireRate[1];
		else
			Fb_FireRate = default.FireRate[0];
	}
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + Fb_FireRate);
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

defaultproperties
{
	Name="Default__DKWrapper_Skill_FireStorm"
}
