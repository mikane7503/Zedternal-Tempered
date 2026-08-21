// Wrapper for ZedternalReborn.WMUpgrade_Skill_TightChoke
class ZTWrapper_Skill_TightChoke extends WMUpgrade_Skill_TightChoke config(ZedternalUnlimited);

var config array<float> Cfg_Spread;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Spread[0] = 0.4f;
		default.Cfg_Spread[1] = 0.7f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Spread.Length = 2;
		default.Cfg_Spread[0] = 0.400000f;
		default.Cfg_Spread[1] = 0.700000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyTightChokePassive(out float tightChokeFactor, int upgLevel)
{
	local float Fb_Spread;

	if (default.Cfg_Spread.Length > 0 && default.Cfg_Spread[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Spread.Length > 1)
			Fb_Spread = default.Cfg_Spread[1];
		else
			Fb_Spread = default.Cfg_Spread[0];
	}
	else
	{
		if (upgLevel > 1 && default.Spread.Length > 1)
			Fb_Spread = default.Spread[1];
		else
			Fb_Spread = default.Spread[0];
	}
	tightChokeFactor -= Fb_Spread;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_TightChoke"
}
