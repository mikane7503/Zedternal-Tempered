// Wrapper for ZedternalReborn.WMUpgrade_Skill_HeavyArmor
class ZTWrapper_Skill_HeavyArmor extends WMUpgrade_Skill_HeavyArmor config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.3f;
		default.Cfg_Armor[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Armor.Length = 2;
		default.Cfg_Armor[0] = 0.300000f;
		default.Cfg_Armor[1] = 0.750000f;
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
	Name="Default__ZTWrapper_Skill_HeavyArmor"
}
