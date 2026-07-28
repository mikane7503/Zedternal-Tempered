// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Analytics
class DKWrapper_Skill_Analytics extends ZRUpgrade_Skill_Analytics
	config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.25f;
		default.Cfg_Bonus[1] = 0.6f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	InHealAmount += DefaultHealAmount * default.Cfg_Bonus[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Analytics"
}
