class ZUTUpgrade_Skill_Brawler extends ZUTUpgrade_Skill_Base;

static function bool CanNotBeGrabbed(int upgLevel, KFPawn OwnerPawn)
{
	return True;
}

defaultproperties
{
	bAllowDeluxe=False

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Brawler"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Brawler'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Brawler_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Brawler"
}
