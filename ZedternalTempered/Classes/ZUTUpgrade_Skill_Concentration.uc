class ZUTUpgrade_Skill_Concentration extends ZUTUpgrade_Skill_Base;

var array<float> Damage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageInstigator != None && DamageInstigator.WorldInfo.TimeDilation < 1)
		InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

defaultproperties
{
	Damage(0)=0.15f
	Damage(1)=0.30f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Concentration"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Concentration'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Concentration_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Concentration"
}
