class ZUTUpgrade_Skill_AcidicRounds extends ZUTUpgrade_Skill_Base;

var const class<KFDamageType> WMDT;

var float maxProbability;
var float maxDamage;
var array<float> damageFactor;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if ((IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_FieldMedic') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_FieldMedic'))
		&& DamageType != None && DamageType != default.WMDT && DamageInstigator != None && MyKFPM != None
		&& !MyKFPM.bIsPoisoned && FRand() < (float(DefaultDamage) * default.maxProbability / default.maxDamage))
	{
		//add poison effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.damageFactor[upgLevel - 1]), DamageInstigator, default.WMDT);
	}
}

defaultproperties
{
	WMDT=class'ZedternalReborn.WMDT_AcidicRounds_DoT'
	maxProbability=1.0f
	maxDamage=75.0f
	damageFactor(0)=0.2f
	damageFactor(1)=0.4f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_AcidicRounds"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_AcidicRounds'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_AcidicRounds_Deluxe'

	Name="Default__ZUTUpgrade_Skill_AcidicRounds"
}
