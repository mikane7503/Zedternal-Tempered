// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Adrenaline
class DKWrapper_Skill_Adrenaline extends ZRUpgrade_Skill_Adrenaline
	config(ZedternalUnlimited);

var config array<float> Cfg_MeleeSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MeleeSpeed[0] = 0.2f;
		default.Cfg_MeleeSpeed[1] = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	local float Fb_MeleeSpeed;

	if (default.Cfg_MeleeSpeed.Length > 0 && default.Cfg_MeleeSpeed[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MeleeSpeed.Length > 1)
			Fb_MeleeSpeed = default.Cfg_MeleeSpeed[1];
		else
			Fb_MeleeSpeed = default.Cfg_MeleeSpeed[0];
	}
	else
	{
		if (upgLevel > 1 && default.MeleeSpeed.Length > 1)
			Fb_MeleeSpeed = default.MeleeSpeed[1];
		else
			Fb_MeleeSpeed = default.MeleeSpeed[0];
	}
	durationFactor = 1.0f / (1.0f / durationFactor + Fb_MeleeSpeed);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Adrenaline"
}
