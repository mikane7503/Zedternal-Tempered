class ZUTUpgrade_Skill_Barbecue extends ZUTUpgrade_Skill_Base;

var array<float> DamageOverTime;
var array<float> Damage;

static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	InDoTScaler += DefaultDotScaler * default.DamageOverTime[upgLevel - 1];
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Freeze') || ClassIsChildOf(DamageType, class'KFDT_Bleeding')))
	InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

defaultproperties
{
	DamageOverTime(0)=0.50f
	DamageOverTime(1)=1.00f
	Damage(0)=0.05f
	Damage(1)=0.10f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Barbecue"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Barbecue'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Barbecue_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Barbecue"
}
