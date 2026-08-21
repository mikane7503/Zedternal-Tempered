// Jekyll skill - Composure: stronger self-heals and a healing surge.
// (Healing only matters out of Hyde, since Mr. Hyde is immune and at full health -
//  so these bonuses are effectively the doctor's domain and need no form gate.)
class ZTUpgrade_Skill_Composure extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> HealBonus;
var config array<float> SurgePct;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HealBonus[0] = 0.20f;  default.HealBonus[1] = 0.40f;
		default.SurgePct[0] = 0.10f;   default.SurgePct[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	InHealAmount += DefaultHealAmount * default.HealBonus[upgLevel - 1];
}

static simulated function GetSelfHealingSurgePct(out float InHealingPct, int upgLevel)
{
	InHealingPct += default.SurgePct[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Composure"
	UpgradeName="Composure"
	upgradeDescription(0)="<font color=\"#15d7fa\">Healing</font> you receive is <font color=\"#77d914\">+20%</font> stronger, with a <font color=\"#77d914\">+10%</font> self-healing surge."
	upgradeDescription(1)="<font color=\"#15d7fa\">Healing</font> you receive is <font color=\"#77d914\">+40%</font> stronger, with a <font color=\"#77d914\">+20%</font> self-healing surge."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Composure'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Composure_Deluxe'
	Name="Default__ZTUpgrade_Skill_Composure"
}
