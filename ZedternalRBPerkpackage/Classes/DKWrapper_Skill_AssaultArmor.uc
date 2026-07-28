// Wrapper for ZedternalReborn.WMUpgrade_Skill_AssaultArmor
class DKWrapper_Skill_AssaultArmor extends WMUpgrade_Skill_AssaultArmor
	config(ZedternalUnlimited);

var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor[0] = 0.5f;
		default.Cfg_Armor[1] = 1.0f;

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
	Name="Default__DKWrapper_Skill_AssaultArmor"
}
