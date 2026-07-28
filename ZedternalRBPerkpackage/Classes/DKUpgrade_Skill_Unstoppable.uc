// Hyde skill - Unstoppable: can't be grabbed while transformed; deluxe also ignores zed-time slow.
class DKUpgrade_Skill_Unstoppable extends DKUpgrade_Skill;

static function bool CanNotBeGrabbed(int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return false;
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	return (H != None && H.bHyde);
}

static simulated function bool IsUnAffectedByZedTime(int upgLevel, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;
	if (upgLevel < 2 || OwnerPawn == None) return false;   // deluxe only
	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	return (H != None && H.bHyde);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Unstoppable"
	UpgradeName="Unstoppable"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, you <font color=\"#66cc00\">cannot be grabbed</font>."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, you <font color=\"#66cc00\">cannot be grabbed</font> and move at full speed during <font color=\"#15d7fa\">ZED-time</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Unstoppable'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Unstoppable_Deluxe'
	Name="Default__DKUpgrade_Skill_Unstoppable"
}
