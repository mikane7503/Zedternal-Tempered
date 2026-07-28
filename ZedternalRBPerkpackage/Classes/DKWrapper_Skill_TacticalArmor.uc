// Wrapper for ZedternalReborn.WMUpgrade_Skill_TacticalArmor
class DKWrapper_Skill_TacticalArmor extends WMUpgrade_Skill_TacticalArmor
	config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.2f;
		default.Cfg_Armor[1] = 0.5f;

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
	Name="Default__DKWrapper_Skill_TacticalArmor"
}
