// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ExtraPockets
class DKWrapper_Skill_ExtraPockets extends ZRUpgrade_Skill_ExtraPockets
	config(ZedternalUnlimited);

var config array<int> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 4;
		default.Cfg_Bonus[1] = 8;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ApplyWeightLimits(out int InWeightLimit, int DefaultWeightLimit, int upgLevel)
{
	InWeightLimit += default.Cfg_Bonus[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ExtraPockets"
}
