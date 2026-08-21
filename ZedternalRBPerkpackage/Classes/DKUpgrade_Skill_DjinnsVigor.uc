// Djinn's Vigor - universal: max health blessing.
class DKUpgrade_Skill_DjinnsVigor extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> HealthBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HealthBonus[0] = 0.10f;
		default.HealthBonus[1] = 0.15f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * default.HealthBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_DjinnsVigor"

	UpgradeName="Djinn's Vigor"
	upgradeDescription(0)="<font color=\"#77d914\">+10% Max Health</font>."
	upgradeDescription(1)="<font color=\"#77d914\">+15% Max Health</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DjinnsVigor'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DjinnsVigor_Deluxe'
	Name="Default__DKUpgrade_Skill_DjinnsVigor"
}
