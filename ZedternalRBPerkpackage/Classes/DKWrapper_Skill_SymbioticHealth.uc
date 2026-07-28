// Wrapper for ZedternalReborn.WMUpgrade_Skill_SymbioticHealth
class DKWrapper_Skill_SymbioticHealth extends WMUpgrade_Skill_SymbioticHealth
	config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.1f;
		default.Cfg_Bonus[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += DefaultHealth * default.Cfg_Bonus[upgLevel - 1];
}

static simulated function GetSelfHealingSurgePct(out float InHealingPct, int upgLevel)
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
	InHealingPct += Fb_Bonus;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_SymbioticHealth"
}
