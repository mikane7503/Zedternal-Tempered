// Wrapper for ZedternalReborn.WMUpgrade_Skill_Penetrator
class ZTWrapper_Skill_Penetrator extends WMUpgrade_Skill_Penetrator config(ZedternalUnlimited);

var config array<float> Cfg_Penetration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Penetration[0] = 2.0f;
		default.Cfg_Penetration[1] = 5.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Penetration.Length = 2;
		default.Cfg_Penetration[0] = 1.000000f;
		default.Cfg_Penetration[1] = 2.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyPenetrationPassive(out float penetrationFactor, int upgLevel)
{
	local float Fb_Penetration;

	if (default.Cfg_Penetration.Length > 0 && default.Cfg_Penetration[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Penetration.Length > 1)
			Fb_Penetration = default.Cfg_Penetration[1];
		else
			Fb_Penetration = default.Cfg_Penetration[0];
	}
	else
	{
		if (upgLevel > 1 && default.Penetration.Length > 1)
			Fb_Penetration = default.Penetration[1];
		else
			Fb_Penetration = default.Penetration[0];
	}
	penetrationFactor += Fb_Penetration;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Penetrator"
}
