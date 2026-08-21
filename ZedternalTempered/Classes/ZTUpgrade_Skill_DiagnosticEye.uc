// Jekyll skill - Diagnostic Eye: see zed health bars while NOT transformed (pick your targets).
class ZTUpgrade_Skill_DiagnosticEye extends ZTUpgrade_Skill;

static simulated function bool CanSeeEnemyHealth(int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return false;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None && H.bHyde) return false;
	return true;
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_DiagnosticEye"
	UpgradeName="Diagnostic Eye"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, you can see <font color=\"#66cc00\">enemy health bars</font>."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, you can see <font color=\"#66cc00\">enemy health bars</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DiagnosticEye'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DiagnosticEye_Deluxe'
	Name="Default__ZTUpgrade_Skill_DiagnosticEye"
}
