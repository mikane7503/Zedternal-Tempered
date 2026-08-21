class ZUTUpgrade_Skill_Napalm extends ZUTUpgrade_Skill_Base;

var const class<KFDamageType> WMDT;

var array<float> IgniteChance;
var array<float> SpreadChance;
var array<float> DamageFactor;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.WMDT && DamageInstigator != None && MyKFPM != None
		&& FRand() < default.IgniteChance[upgLevel - 1])
	{
		//add fire/microwave effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.DamageFactor[upgLevel - 1]), DamageInstigator, default.WMDT);
	}
}

static simulated function bool CanSpreadNapalm(int upgLevel, KFPawn OwnerPawn)
{
	return FRand() < default.SpreadChance[upgLevel - 1];
}

defaultproperties
{
	WMDT=class'ZedternalReborn.WMDT_Napalm'
	IgniteChance(0)=0.15f
	IgniteChance(1)=0.30f
	SpreadChance(0)=0.15f
	SpreadChance(1)=0.30f
	DamageFactor(0)=0.2f
	DamageFactor(1)=0.4f

	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZUTUpgrade_Skill_Napalm"
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Napalm"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Napalm'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Napalm_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Napalm"
}
