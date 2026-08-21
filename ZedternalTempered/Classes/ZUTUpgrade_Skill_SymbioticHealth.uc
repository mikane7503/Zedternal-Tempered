class ZUTUpgrade_Skill_SymbioticHealth extends ZUTUpgrade_Skill_Base;

var array<float> Bonus;

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += DefaultHealth * default.Bonus[upgLevel - 1];
}

static simulated function GetSelfHealingSurgePct(out float InHealingPct, int upgLevel)
{
	InHealingPct += default.Bonus[upgLevel - 1];
}

defaultproperties
{
	Bonus(0)=0.1f
	Bonus(1)=0.20f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_SymbioticHealth"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_SymbioticHealth'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_SymbioticHealth_Deluxe'

	Name="Default__ZUTUpgrade_Skill_SymbioticHealth"
}
