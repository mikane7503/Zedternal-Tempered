class ZUTUpgrade_Skill_Massacre extends ZUTUpgrade_Skill_Base;

var array<float> MeleeDamage, Damage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && static.IsMeleeDamageType(DamageType))
		InDamage += int(float(DefaultDamage) * default.MeleeDamage[upgLevel - 1]);
	else
		InDamage += int(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

defaultproperties
{
	Damage(0)=0.05f
	Damage(1)=0.10f
	MeleeDamage(0)=0.10f
	MeleeDamage(1)=0.20f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Massacre"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Massacre'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Massacre_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Massacre"
}
