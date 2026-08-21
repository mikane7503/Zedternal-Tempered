// Wrapper for ZedternalReborn.WMUpgrade_Skill_TacticalArmor
class ZTWrapper_Skill_TacticalArmor extends WMUpgrade_Skill_TacticalArmor config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.2f;
		default.Cfg_Armor[1] = 0.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Armor.Length = 2;
		default.Cfg_Armor[0] = 0.200000f;
		default.Cfg_Armor[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
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
	Name="Default__ZTWrapper_Skill_TacticalArmor"
}
