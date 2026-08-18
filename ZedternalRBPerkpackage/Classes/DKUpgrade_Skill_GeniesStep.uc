// Genie's Step - universal: movement speed blessing.
class DKUpgrade_Skill_GeniesStep extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> SpeedBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SpeedBonus[0] = 0.05f;
		default.SpeedBonus[1] = 0.10f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	InSpeed += DefaultSpeed * default.SpeedBonus[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_GeniesStep"

	UpgradeName="Genie's Step"
	upgradeDescription(0)="<font color=\"#77d914\">+5% Movement Speed</font>."
	upgradeDescription(1)="<font color=\"#77d914\">+10% Movement Speed</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GeniesStep'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GeniesStep_Deluxe'
	Name="Default__DKUpgrade_Skill_GeniesStep"
}
