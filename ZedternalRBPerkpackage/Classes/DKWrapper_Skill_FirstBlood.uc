// Wrapper for ZedternalReborn.WMUpgrade_Skill_FirstBlood
class DKWrapper_Skill_FirstBlood extends WMUpgrade_Skill_FirstBlood
	config(ZedternalUnlimited);

var config array<float> Cfg_DamageDelta;
var config array<float> Cfg_DamageMax;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageDelta[0] = 0.05f;
		default.Cfg_DamageDelta[1] = 0.1f;
		default.Cfg_DamageMax[0] = 2.0f;
		default.Cfg_DamageMax[1] = 5.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_FirstBlood_Helper UPG;

	if (ClassIsChildOf(DamageType, class'KFDT_Ballistic') && DamageInstigator != None && DamageInstigator.Pawn != None)
	{
		UPG = GetHelper(KFPawn(DamageInstigator.Pawn));
		if (UPG != None && UPG.bActive)
		{
			InDamage += DefaultDamage * FMin(default.Cfg_DamageMax[upgLevel - 1], default.Cfg_DamageDelta[upgLevel - 1] * MyKFW.MagazineCapacity[0]);
			UPG.StartFirstBloodTimer();
		}
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_FirstBlood"
}
