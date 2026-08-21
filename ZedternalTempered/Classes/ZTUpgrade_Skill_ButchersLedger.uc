class ZTUpgrade_Skill_ButchersLedger extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillMeleeLedgerBonus=class'ZTUpgrade_Perk_Diablo'.default.MeleeLedgerBonus[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillMeleeLedgerBonus=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ButchersLedger"
	UpgradeName="Butcher's Ledger"
	UpgradeDescription(0)="Melee damage contributes <font color=\"#FFD700\">25%</font> more to Deathwave."
	UpgradeDescription(1)="Melee damage contributes <font color=\"#FFD700\">50%</font> more to Deathwave."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_ButchersLedger"
}