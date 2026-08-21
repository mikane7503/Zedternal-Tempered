class ZUTUpgrade_Skill_ImpactRounds extends ZUTUpgrade_Skill_Base;

var array<float> Damage, Stumble;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Ballistic'))
		InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

static function ModifyStumblePowerPassive(out float stumblePowerFactor, int upgLevel)
{
	stumblePowerFactor += default.Stumble[upgLevel - 1];
}

defaultproperties
{
	Damage(0)=0.05f
	Damage(1)=0.10f
	Stumble(0)=0.15f
	Stumble(1)=0.30f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_ImpactRounds"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_ImpactRounds'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_ImpactRounds_Deluxe'

	Name="Default__ZUTUpgrade_Skill_ImpactRounds"
}
