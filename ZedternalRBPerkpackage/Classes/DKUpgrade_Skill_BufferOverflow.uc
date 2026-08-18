// Buffer Overflow - universal glitch tradeoff: bigger mags, slower reloads.
class DKUpgrade_Skill_BufferOverflow extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> MagBonus;
var config array<float> ReloadPenalty;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MagBonus[0] = 0.30f;
		default.MagBonus[1] = 0.50f;
		default.ReloadPenalty[0] = 0.15f;
		default.ReloadPenalty[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	magazineCapacityFactor += default.MagBonus[upgLevel - 1];
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor - default.ReloadPenalty[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_BufferOverflow"

	UpgradeName="Buffer Overflow"
	upgradeDescription(0)="<font color=\"#00ff00\">Magazine size +30%</font> but <font color=\"#be4d25\">Reload Speed -15%</font>."
	upgradeDescription(1)="<font color=\"#00ff00\">Magazine size +50%</font> but <font color=\"#be4d25\">Reload Speed -20%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BufferOverflow'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BufferOverflow_Deluxe'
	Name="Default__DKUpgrade_Skill_BufferOverflow"
}
