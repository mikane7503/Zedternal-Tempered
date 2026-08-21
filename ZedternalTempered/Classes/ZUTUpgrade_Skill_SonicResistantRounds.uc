class ZUTUpgrade_Skill_SonicResistantRounds extends ZUTUpgrade_Skill_Base;

static simulated function bool ProjSirenResist(int upgLevel, KFPawn OwnerPawn)
{
	return True;
}

defaultproperties
{
	bAllowDeluxe=False

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_SonicResistantRounds"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_SonicResistantRounds'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_SonicResistantRounds_Deluxe'

	Name="Default__ZUTUpgrade_Skill_SonicResistantRounds"
}
