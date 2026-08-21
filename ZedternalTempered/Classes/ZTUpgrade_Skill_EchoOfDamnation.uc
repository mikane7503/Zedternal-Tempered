class ZTUpgrade_Skill_EchoOfDamnation extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillEchoPct=class'ZTUpgrade_Perk_Diablo'.default.EchoPct[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillEchoPct=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_EchoOfDamnation"
	UpgradeName="Echo of Damnation"
	UpgradeDescription(0)="Deathwave repeats <font color=\"#FFD700\">15%</font> of its damage once."
	UpgradeDescription(1)="Deathwave repeats <font color=\"#FFD700\">30%</font> of its damage once."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_EchoOfDamnation"
}