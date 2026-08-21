// Wrapper for ZedternalReborn.WMUpgrade_Skill_Safeguard
class ZTWrapper_Skill_Safeguard extends WMUpgrade_Skill_Safeguard config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.2f;
		default.Cfg_Bonus[1] = 0.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Bonus.Length = 2;
		default.Cfg_Bonus[0] = 0.200000f;
		default.Cfg_Bonus[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealAmountPassive(out float healAmountFactor, int upgLevel)
{
	healAmountFactor += default.Cfg_Bonus[upgLevel - 1];
}

static simulated function ModifyHealerRechargeTime(out float InRechargeTime, float DefaultRechargeTime, int upgLevel)
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
	InRechargeTime = DefaultRechargeTime / (DefaultRechargeTime / InRechargeTime + Fb_Bonus);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Safeguard"
}
