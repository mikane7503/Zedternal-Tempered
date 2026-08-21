// Wrapper for ZedternalReborn.WMUpgrade_Skill_Empathy
class ZTWrapper_Skill_Empathy extends WMUpgrade_Skill_Empathy config(ZedternalUnlimited);

var config array<float> Cfg_Healing;
var config array<float> Cfg_SelfHealing;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Healing[0] = 0.25f;
		default.Cfg_Healing[1] = 0.5f;
		default.Cfg_SelfHealing[0] = 0.1f;
		default.Cfg_SelfHealing[1] = 0.25f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Healing.Length = 2;
		default.Cfg_Healing[0] = 0.250000f;
		default.Cfg_Healing[1] = 0.500000f;
		default.Cfg_SelfHealing.Length = 2;
		default.Cfg_SelfHealing[0] = 0.100000f;
		default.Cfg_SelfHealing[1] = 0.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	InHealAmount += DefaultHealAmount * default.Cfg_Healing[upgLevel - 1];
}

static simulated function GetSelfHealingSurgePct(out float InHealingPct, int upgLevel)
{
	local float Fb_SelfHealing;

	if (default.Cfg_SelfHealing.Length > 0 && default.Cfg_SelfHealing[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_SelfHealing.Length > 1)
			Fb_SelfHealing = default.Cfg_SelfHealing[1];
		else
			Fb_SelfHealing = default.Cfg_SelfHealing[0];
	}
	else
	{
		if (upgLevel > 1 && default.SelfHealing.Length > 1)
			Fb_SelfHealing = default.SelfHealing[1];
		else
			Fb_SelfHealing = default.SelfHealing[0];
	}
	InHealingPct += Fb_SelfHealing;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Empathy"
}
