// Wrapper for ZedternalReborn.WMUpgrade_Skill_Vampire
class DKWrapper_Skill_Vampire extends WMUpgrade_Skill_Vampire
	config(ZedternalUnlimited);

var config array<int> Cfg_MeleeVampire;
var config array<int> Cfg_WeapVampire;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MeleeVampire[0] = 3;
		default.Cfg_MeleeVampire[1] = 8;
		default.Cfg_WeapVampire[0] = 2;
		default.Cfg_WeapVampire[1] = 5;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
	if (DT != None && static.IsMeleeDamageType(DT))
		InHealth += default.Cfg_MeleeVampire[upgLevel - 1];
	else
		InHealth += default.Cfg_WeapVampire[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Vampire"
}
