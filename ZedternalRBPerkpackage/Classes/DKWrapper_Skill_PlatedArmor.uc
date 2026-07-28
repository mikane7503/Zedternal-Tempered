// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_PlatedArmor
class DKWrapper_Skill_PlatedArmor extends ZRUpgrade_Skill_PlatedArmor
	config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.3f;
		default.Cfg_Armor[1] = 0.60f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += Round(float(DefaultArmor) * default.Cfg_Armor[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_PlatedArmor"
}
