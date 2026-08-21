// Second Wind-Up - universal: always-on weapon switch and reload speed.
class ZTUpgrade_Skill_SecondWindUp extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> SwitchBonus;
var config array<float> ReloadBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SwitchBonus[0] = 0.10f;
		default.SwitchBonus[1] = 0.18f;
		default.ReloadBonus[0] = 0.10f;
		default.ReloadBonus[1] = 0.18f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyWeaponSwitchTimePassive(out float switchTimeFactor, int upgLevel)
{
	switchTimeFactor = 1.0f / (1.0f / switchTimeFactor + default.SwitchBonus[upgLevel - 1]);
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor + default.ReloadBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_SecondWindUp"

	UpgradeName="Second Wind-Up"
	upgradeDescription(0)="<font color=\"#77d914\">+10%</font> Weapon Switch Speed and <font color=\"#77d914\">+10%</font> Reload Speed."
	upgradeDescription(1)="<font color=\"#77d914\">+18%</font> Weapon Switch Speed and <font color=\"#77d914\">+18%</font> Reload Speed."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SecondWindUp'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SecondWindUp_Deluxe'
	Name="Default__ZTUpgrade_Skill_SecondWindUp"
}
