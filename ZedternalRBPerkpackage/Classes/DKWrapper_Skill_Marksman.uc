// Wrapper for ZedternalReborn.WMUpgrade_Skill_Marksman
class DKWrapper_Skill_Marksman extends WMUpgrade_Skill_Marksman
	config(ZedternalUnlimited);

var config array<float> Cfg_Speed;
var config array<float> Cfg_RateOfFire;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Speed[0] = 0.05f;
		default.Cfg_Speed[1] = 0.1f;
		default.Cfg_RateOfFire[0] = 0.15f;
		default.Cfg_RateOfFire[1] = 0.4f;

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

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local float Fb_Speed;

	if (default.Cfg_Speed.Length > 0 && default.Cfg_Speed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Speed.Length > 1)
			Fb_Speed = default.Cfg_Speed[1];
		else
			Fb_Speed = default.Cfg_Speed[0];
	}
	else
	{
		if (upgLevel > 1 && default.Speed.Length > 1)
			Fb_Speed = default.Speed[1];
		else
			Fb_Speed = default.Speed[0];
	}
	speedFactor += Fb_Speed;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Marksman"
}
