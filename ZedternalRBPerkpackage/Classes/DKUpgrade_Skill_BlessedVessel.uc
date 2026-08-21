// Blessed Vessel - universal: flat max armor blessing.
class DKUpgrade_Skill_BlessedVessel extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> ArmorBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ArmorBonus[0] = 10;
		default.ArmorBonus[1] = 20;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += default.ArmorBonus[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_BlessedVessel"

	UpgradeName="Blessed Vessel"
	upgradeDescription(0)="<font color=\"#77d914\">+10 Max Armor</font>."
	upgradeDescription(1)="<font color=\"#77d914\">+20 Max Armor</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BlessedVessel'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BlessedVessel_Deluxe'
	Name="Default__DKUpgrade_Skill_BlessedVessel"
}
