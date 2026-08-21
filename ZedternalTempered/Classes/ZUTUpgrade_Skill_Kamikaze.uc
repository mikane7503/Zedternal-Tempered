class ZUTUpgrade_Skill_Kamikaze extends ZUTUpgrade_Skill_Base;

var float DamageDeluxe;

static simulated function bool ShouldSacrifice(int upgLevel, KFPawn OwnerPawn)
{
	return True;
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	if (upgLevel > 1)
		damageFactor += default.DamageDeluxe;
}

defaultproperties
{
	bAllowDeluxe=False
	DamageDeluxe=0.25f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Kamikaze"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Kamikaze'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Kamikaze_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Kamikaze"
}
