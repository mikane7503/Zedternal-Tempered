class ZTUpgrade_Skill_DemonSkin extends ZTUpgrade_Skill;
static simulated function InitiateWeapon(int L,KFWeapon W,KFPawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillDemonSkinResistance=class'ZTUpgrade_Perk_Diablo'.default.DemonSkinResistance[L-1];}
static simulated function DeleteHelperClass(Pawn P){local ZTUpgrade_Perk_Diablo_Helper H;H=class'ZTUpgrade_Perk_Diablo'.static.GetHelper(P);if(H!=None)H.SkillDemonSkinResistance=0;}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_DemonSkin"
	UpgradeName="Demon Skin"
	UpgradeDescription(0)="After Deathwave, gain <font color=\"#77d914\">10% damage resistance</font> for 5 seconds."
	UpgradeDescription(1)="After Deathwave, gain <font color=\"#77d914\">20% damage resistance</font> for 5 seconds."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConsumingFlame_Deluxe'
	Name="Default__ZTUpgrade_Skill_DemonSkin"
}