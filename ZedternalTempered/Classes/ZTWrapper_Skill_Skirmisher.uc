// Wrapper for ZedternalReborn.WMUpgrade_Skill_Skirmisher
class ZTWrapper_Skill_Skirmisher extends WMUpgrade_Skill_Skirmisher config(ZedternalUnlimited);

var config array<float> Cfg_MoveSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed[0] = 0.05f;
		default.Cfg_MoveSpeed[1] = 0.1f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MoveSpeed.Length = 2;
		default.Cfg_MoveSpeed[0] = 0.050000f;
		default.Cfg_MoveSpeed[1] = 0.100000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local float Fb_MoveSpeed;

	if (default.Cfg_MoveSpeed.Length > 0 && default.Cfg_MoveSpeed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MoveSpeed.Length > 1)
			Fb_MoveSpeed = default.Cfg_MoveSpeed[1];
		else
			Fb_MoveSpeed = default.Cfg_MoveSpeed[0];
	}
	else
	{
		if (upgLevel > 1 && default.MoveSpeed.Length > 1)
			Fb_MoveSpeed = default.MoveSpeed[1];
		else
			Fb_MoveSpeed = default.MoveSpeed[0];
	}
	speedFactor += Fb_MoveSpeed;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Skirmisher"
}
