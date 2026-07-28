// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ArcticChill
class DKWrapper_Skill_ArcticChill extends ZRUpgrade_Skill_ArcticChill
	config(ZedternalUnlimited);

var config array<float> Cfg_RateOfFire;
var config float Cfg_Snare;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_RateOfFire[0] = 0.10f;
		default.Cfg_RateOfFire[1] = 0.25f;
		default.Cfg_Snare = 30.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifySnarePower(out float InSnarePower, float DefaultSnarePower, int upgLevel, optional class<DamageType> DamageType, optional byte BodyPart)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Freeze'))
		InSnarePower += DefaultSnarePower * default.Cfg_Snare;
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
	Name="Default__DKWrapper_Skill_ArcticChill"
}
