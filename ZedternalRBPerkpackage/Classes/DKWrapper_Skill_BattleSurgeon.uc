// Wrapper for ZedternalReborn.WMUpgrade_Skill_BattleSurgeon
class DKWrapper_Skill_BattleSurgeon extends WMUpgrade_Skill_BattleSurgeon
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config array<float> Cfg_OtherDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.2f;
		default.Cfg_Damage[1] = 0.5f;
		default.Cfg_OtherDamage[0] = 0.1f;
		default.Cfg_OtherDamage[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if ((MyKFW != None && IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_FieldMedic')) || (DamageType != None && IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_FieldMedic')))
		InDamage += DefaultDamage * default.Cfg_Damage[upgLevel - 1];
	else
		InDamage += DefaultDamage * default.Cfg_OtherDamage[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_BattleSurgeon"
}
