class ZTUpgrade_Skill_VoidChamber extends ZTUpgrade_Skill;
static simulated function GetReloadRateScale(out float R,int L,KFWeapon W,KFPawn P){if(class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,None))R=1.0/(1.0/R+(L==1?0.075:0.15));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_VoidChamber"
	UpgradeName="Void Chamber"
	UpgradeDescription(0)="Demolitionist weapon reload speed +7.5%."
	UpgradeDescription(1)="Demolitionist weapon reload speed +15%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_VoidChamber"
}