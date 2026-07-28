// ===================================================================
// DKUpgrade_Skill_Fleetfoot - Speedfreak general skill (not Blink-specific).
//
// Flat, always-on movement speed (Standard +8%, Deluxe +15%). Uses the
// optimized passive hook, so it stacks additively with the perk's own
// per-rank move-speed passive. No helper needed.
// ===================================================================
class DKUpgrade_Skill_Fleetfoot extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> MoveSpeed;    // [standard, deluxe] fraction
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MoveSpeed[0] = 0.08f;
		default.MoveSpeed[1] = 0.15f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	speedFactor += default.MoveSpeed[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Fleetfoot"

	UpgradeName="Fleetfoot"
	upgradeDescription(0)="Move <font color=\"#77d914\">8%</font> <font color=\"#15d7fa\">faster</font> at all times."
	upgradeDescription(1)="Move <font color=\"#77d914\">15%</font> <font color=\"#15d7fa\">faster</font> at all times."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Fleetfoot'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Fleetfoot_Deluxe'

	Name="Default__DKUpgrade_Skill_Fleetfoot"
}
