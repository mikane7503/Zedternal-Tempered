class ZUTUpgrade_Skill_HighImpactRound extends ZUTUpgrade_Skill_Base;

var array<float> Knockdown;

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive'))
		InKnockdownPower += DefaultKnockdownPower * default.Knockdown[upgLevel - 1];
}

defaultproperties
{
	Knockdown(0)=0.30f
	Knockdown(1)=0.60f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_HighImpactRound"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HighImpactRound'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HighImpactRound_Deluxe'

	Name="Default__ZUTUpgrade_Skill_HighImpactRound"
}
