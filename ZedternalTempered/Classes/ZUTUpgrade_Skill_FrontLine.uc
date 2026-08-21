class ZUTUpgrade_Skill_FrontLine extends ZUTUpgrade_Skill_Base;

var array<float> SelfExplosiveResistance, OtherResistance;

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive') && KFPlayerController(InstigatedBy) != None)
		InDamage -= DefaultDamage * default.SelfExplosiveResistance[upgLevel - 1];
	else
		InDamage -= DefaultDamage * default.OtherResistance[upgLevel - 1];
}

defaultproperties
{
	SelfExplosiveResistance(0)=0.20f
	SelfExplosiveResistance(1)=0.40f
	OtherResistance(0)=0.02f
	OtherResistance(1)=0.04f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_FrontLine"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_FrontLine'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_FrontLine_Deluxe'

	Name="Default__ZUTUpgrade_Skill_FrontLine"
}
