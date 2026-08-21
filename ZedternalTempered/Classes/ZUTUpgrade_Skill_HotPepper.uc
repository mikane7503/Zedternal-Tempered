class ZUTUpgrade_Skill_HotPepper extends ZUTUpgrade_Skill_Base;

var const class<KFDamageType> WMDT;
var array<float> IgniteChance;
var array<int> BurnDamage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.WMDT && DamageInstigator != None && MyKFPM != None
		&& FRand() < default.IgniteChance[upgLevel - 1])
	{
		MyKFPM.ApplyDamageOverTime(default.BurnDamage[upgLevel - 1], DamageInstigator, default.WMDT);
	}
}

defaultproperties
{
	WMDT=class'ZedternalReborn.WMDT_Napalm'
	IgniteChance(0)=0.15f
	IgniteChance(1)=0.30f
	BurnDamage(0)=10
	BurnDamage(1)=20
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZUTUpgrade_Skill_HotPepper"
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_HotPepper"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HotPepper'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HotPepper_Deluxe'
	Name="Default__ZUTUpgrade_Skill_HotPepper"
}
