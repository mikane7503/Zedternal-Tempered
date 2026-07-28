// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Bloodthirst
class DKWrapper_Skill_Bloodthirst extends ZRUpgrade_Skill_Bloodthirst
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
		default.Cfg_WeapVampire[0] = 1;
		default.Cfg_WeapVampire[1] = 2;

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
	Name="Default__DKWrapper_Skill_Bloodthirst"
}
