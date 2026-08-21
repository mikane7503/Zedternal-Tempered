class ZTUpgrade_Skill_ImpatienceOfHell extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillCooldownReduction=class'ZTUpgrade_Perk_Diablo'.default.CooldownReduction[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillCooldownReduction=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ImpatienceOfHell"
	UpgradeName="Impatience of Hell"
	UpgradeDescription(0)="Deathwave returns <font color=\"#FFD700\">10 seconds</font> sooner."
	UpgradeDescription(1)="Deathwave returns <font color=\"#FFD700\">20 seconds</font> sooner."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_ImpatienceOfHell"
}