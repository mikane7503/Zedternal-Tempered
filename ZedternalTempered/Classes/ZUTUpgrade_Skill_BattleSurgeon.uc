class ZUTUpgrade_Skill_BattleSurgeon extends ZUTUpgrade_Skill_Base;

var array<float> Damage, OtherDamage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if ((MyKFW != None && IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_FieldMedic')) || (DamageType != None && IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_FieldMedic')))
		InDamage += DefaultDamage * default.Damage[upgLevel - 1];
	else
		InDamage += DefaultDamage * default.OtherDamage[upgLevel - 1];
}

defaultproperties
{
	Damage(0)=0.15f
	Damage(1)=0.30f
	OtherDamage(0)=0.05f
	OtherDamage(1)=0.10f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_BattleSurgeon"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BattleSurgeon'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BattleSurgeon_Deluxe'

	Name="Default__ZUTUpgrade_Skill_BattleSurgeon"
}
