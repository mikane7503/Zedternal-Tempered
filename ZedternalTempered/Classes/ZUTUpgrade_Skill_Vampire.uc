class ZUTUpgrade_Skill_Vampire extends ZUTUpgrade_Skill_Base;

var array<int> MeleeVampire, WeapVampire;

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
	if (DT != None && static.IsMeleeDamageType(DT))
		InHealth += default.MeleeVampire[upgLevel - 1];
	else
		InHealth += default.WeapVampire[upgLevel - 1];
}

defaultproperties
{
	MeleeVampire(0)=2
	MeleeVampire(1)=4
	WeapVampire(0)=1
	WeapVampire(1)=2

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_Vampire"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Vampire'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_Vampire_Deluxe'

	Name="Default__ZUTUpgrade_Skill_Vampire"
}
