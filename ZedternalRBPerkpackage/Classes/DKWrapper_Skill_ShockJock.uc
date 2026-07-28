// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ShockJock
class DKWrapper_Skill_ShockJock extends ZRUpgrade_Skill_ShockJock
	config(ZedternalUnlimited);

var config array<float> Cfg_Chance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Chance[0] = 0.2f;
		default.Cfg_Chance[1] = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function bool ShouldShrapnel(int upgLevel)
{
	return fRand() <= default.Cfg_Chance[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ShockJock"
}
