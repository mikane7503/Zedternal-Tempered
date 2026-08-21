class ZTUpgrade_Skill_Apocalypse extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillApocalypsePct=class'ZTUpgrade_Perk_Diablo'.default.ApocalypsePct[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillApocalypsePct=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Apocalypse"
	UpgradeName="Apocalypse"
	UpgradeDescription(0)="At level 20, Hell Deathwave deals <font color=\"#FFD700\">+5%</font> stored damage."
	UpgradeDescription(1)="At level 20, Hell Deathwave deals <font color=\"#FFD700\">+10%</font> stored damage."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_Apocalypse"
}