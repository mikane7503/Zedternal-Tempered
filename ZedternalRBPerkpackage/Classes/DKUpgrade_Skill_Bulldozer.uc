// ===================================================================
// DKUpgrade_Skill_Bulldozer - Speedfreak general skill (not Blink-specific).
//
// Barrel through the horde: sprinting into ZEDs knocks them down on
// contact. Standard floors trash and medium ZEDs; Deluxe also floors
// large ZEDs (never bosses). Pure crowd control - no healing, no damage
// resistance. Uses the ShouldKnockDownOnBump boolean hook; no helper.
// ===================================================================
class DKUpgrade_Skill_Bulldozer extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function bool ShouldKnockDownOnBump(int upgLevel, KFPawn_Monster KFPM, KFPawn OwnerPawn)
{
	if (KFPM == None || OwnerPawn == None)
		return false;

	// Only while sprinting, and never bosses.
	if (!OwnerPawn.bIsSprinting)
		return false;
	if (KFPM.IsABoss())
		return false;

	// Trash + medium ZEDs: both tiers. Large ZEDs: Deluxe only.
	if (!KFPM.IsLargeZed())
		return true;

	return upgLevel >= 2;
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Bulldozer"

	UpgradeName="Bulldozer"
	upgradeDescription(0)="<font color=\"#15d7fa\">Sprinting</font> into ZEDs <font color=\"#77d914\">knocks them down</font> on contact."
	upgradeDescription(1)="<font color=\"#15d7fa\">Sprinting</font> into ZEDs <font color=\"#77d914\">knocks them down</font> - now even large ZEDs."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bulldozer'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bulldozer_Deluxe'

	Name="Default__DKUpgrade_Skill_Bulldozer"
}
