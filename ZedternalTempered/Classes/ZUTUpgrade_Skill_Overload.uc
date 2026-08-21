class ZUTUpgrade_Skill_Overload extends ZUTUpgrade_Skill_Base;

var array<float> MagCapacity, MaxAmmo;

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	magazineCapacityFactor += default.MagCapacity[upgLevel - 1];
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	spareAmmoFactor += default.MaxAmmo[upgLevel - 1];
}

defaultproperties
{
	MagCapacity(0)=0.15f
	MagCapacity(1)=0.30f
	MaxAmmo(0)=0.15f
	MaxAmmo(1)=0.30f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Overload"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Overload'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Overload_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Overload"
}
