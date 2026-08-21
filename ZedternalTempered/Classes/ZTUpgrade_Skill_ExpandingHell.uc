class ZTUpgrade_Skill_ExpandingHell extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillRadiusBonus=class'ZTUpgrade_Perk_Diablo'.default.RadiusBonus[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillRadiusBonus=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ExpandingHell"
	UpgradeName="Expanding Hell"
	UpgradeDescription(0)="Deathwave radius increases by <font color=\"#FF4500\">0.5 meters</font>."
	UpgradeDescription(1)="Deathwave radius increases by <font color=\"#FF4500\">1 meter</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_ExpandingHell"
}