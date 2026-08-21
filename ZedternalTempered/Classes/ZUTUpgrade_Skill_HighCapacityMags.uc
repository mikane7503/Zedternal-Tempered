class ZUTUpgrade_Skill_HighCapacityMags extends ZUTUpgrade_Skill_Base;

var array<float> MagCapacity;

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
	InMagazineCapacity += Round(float(DefaultMagazineCapacity) * default.MagCapacity[upgLevel - 1]);
}

defaultproperties
{
	MagCapacity(0)=0.20f
	MagCapacity(1)=0.40f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_HighCapacityMags"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HighCapacityMags'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_HighCapacityMags_Deluxe'

	Name="Default__WMU…6123 tokens truncated…ZedternalReborn.WMUpgrade_Skill_BattleSurgeon"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BattleSurgeon'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BattleSurgeon_Deluxe'

	Name="Default__WMUpgrade_Skill_BattleSurgeon"
}
