class ZTUpgrade_Skill_BloodTribute extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillBloodTributeHealPct=class'ZTUpgrade_Perk_Diablo'.default.BloodTributeHealPct[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillBloodTributeHealPct=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_BloodTribute"
	UpgradeName="Blood Tribute"
	UpgradeDescription(0)="Deathwave restores <font color=\"#77d914\">0.5% max health</font> for each zed hit."
	UpgradeDescription(1)="Deathwave restores <font color=\"#77d914\">1% max health</font> for each zed hit."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_BloodTribute"
}