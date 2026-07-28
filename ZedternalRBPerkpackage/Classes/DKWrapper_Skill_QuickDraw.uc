// Wrapper for ZedternalReborn.WMUpgrade_Skill_QuickDraw
class DKWrapper_Skill_QuickDraw extends WMUpgrade_Skill_QuickDraw
	config(ZedternalUnlimited);

var config array<float> Cfg_SwitchSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SwitchSpeed[0] = 1.0f;
		default.Cfg_SwitchSpeed[1] = 2.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyWeaponSwitchTimePassive(out float switchTimeFactor, int upgLevel)
{
	local float Fb_SwitchSpeed;

	if (default.Cfg_SwitchSpeed.Length > 0 && default.Cfg_SwitchSpeed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_SwitchSpeed.Length > 1)
			Fb_SwitchSpeed = default.Cfg_SwitchSpeed[1];
		else
			Fb_SwitchSpeed = default.Cfg_SwitchSpeed[0];
	}
	else
	{
		if (upgLevel > 1 && default.SwitchSpeed.Length > 1)
			Fb_SwitchSpeed = default.SwitchSpeed[1];
		else
			Fb_SwitchSpeed = default.SwitchSpeed[0];
	}
	switchTimeFactor = 1.0f / (1.0f / switchTimeFactor + Fb_SwitchSpeed);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_QuickDraw"
}
