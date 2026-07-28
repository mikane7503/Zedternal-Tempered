// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_PiercingCold
class DKWrapper_Skill_PiercingCold extends ZRUpgrade_Skill_PiercingCold
	config(ZedternalUnlimited);

var config array<float> Cfg_Penetration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Penetration[0] = 1.0f;
		default.Cfg_Penetration[1] = 2.0f;

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
	Name="Default__DKWrapper_Skill_PiercingCold"
}
