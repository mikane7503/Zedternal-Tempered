// Ascension balance wrapper for the original BoneBreaker skill.
class ZUTUpgrade_Skill_BoneBreaker extends ZedternalReborn.WMUpgrade_Skill_BoneBreaker;

var array<float> AscensionHeadshotDamage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (HitZoneIdx == HZI_Head)
		InDamage += Round(float(DefaultDamage) * default.AscensionHeadshotDamage[upgLevel - 1]);
}

defaultproperties
{
	UpgradeName="ZedternalTempered.ZUTUpgrade_Skill_BoneBreaker"
	Stumble(0)=0.30f
	Stumble(1)=0.60f
	Knockdown(0)=0.20f
	Knockdown(1)=0.30f
	Knockdown(2)=0.40f
	Knockdown(3)=0.60f
	AscensionHeadshotDamage(0)=0.15f
	AscensionHeadshotDamage(1)=0.30f
	Name="Default__ZUTUpgrade_Skill_BoneBreaker"
}
