// Wrapper for ZedternalReborn.WMUpgrade_Skill_AssaultArmor
class ZTWrapper_Skill_AssaultArmor extends WMUpgrade_Skill_AssaultArmor config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.5f;
		default.Cfg_Armor[1] = 1.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Armor.Length = 2;
		default.Cfg_Armor[0] = 0.500000f;
		default.Cfg_Armor[1] = 1.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local WMUpgrade_Skill_AssaultArmor_Helper UPG;

	if (KFPC.Pawn != None)
	{
		UPG = GetHelper(KFPC.Pawn);
		if (UPG != None)
			UPG.GiveArmor(default.Cfg_Armor[upgLevel - 1]);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_AssaultArmor"
}
