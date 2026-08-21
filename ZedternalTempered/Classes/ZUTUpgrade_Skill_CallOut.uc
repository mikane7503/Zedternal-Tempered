class ZUTUpgrade_Skill_CallOut extends ZUTUpgrade_Skill_Base;

static simulated function bool IsCallOutActive(int upgLevel, KFPawn OwnerPawn)
{
	return True;
}

defaultproperties
{
	bAllowDeluxe=False

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_CallOut"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_CallOut'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_CallOut_Deluxe'

	Name="Default__ZUTUpgrade_Skill_CallOut"
}
