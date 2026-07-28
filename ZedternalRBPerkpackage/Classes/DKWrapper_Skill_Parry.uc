// Wrapper for ZedternalReborn.WMUpgrade_Skill_Parry
class DKWrapper_Skill_Parry extends WMUpgrade_Skill_Parry
	config(ZedternalUnlimited);

var config array<float> Cfg_Resistance;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Resistance[0] = 0.3f;
		default.Cfg_Resistance[1] = 0.4f;
		default.Cfg_Damage[0] = 0.3f;
		default.Cfg_Damage[1] = 0.75f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_Parry_Helper UPG;

	if (MyKFW != None && MyKFW.Owner != None)
	{
		UPG = GetHelper(KFPawn(MyKFW.Owner));
		if (UPG != None && UPG.bOn)
			InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_Parry_Helper UPG;

	if (OwnerPawn != None)
	{
		UPG = GetHelper(OwnerPawn);
		if (UPG != None && UPG.bOn)
			InDamage -= Round(float(DefaultDamage) * default.Cfg_Resistance[upgLevel - 1]);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Parry"
}
