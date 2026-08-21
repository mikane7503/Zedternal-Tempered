class ZTUpgrade_Skill_ScorchedWake extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillScorchedWakePct=class'ZTUpgrade_Perk_Diablo'.default.ScorchedWakePct[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillScorchedWakePct=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ScorchedWake"
	UpgradeName="Scorched Wake"
	UpgradeDescription(0)="Deathwave adds fire damage equal to <font color=\"#FF4500\">5%</font> of its hit."
	UpgradeDescription(1)="Deathwave adds fire damage equal to <font color=\"#FF4500\">10%</font> of its hit."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_ScorchedWake"
}