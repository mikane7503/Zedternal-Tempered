class ZTUpgrade_Skill_HastyEnd extends ZTUpgrade_Skill;
static simulated function ModifyRateOfFire(out float R,float Base,int L,KFWeapon W){if(class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,None))R=Base/(1.0+(L==1?0.05:0.10));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_HastyEnd"
	UpgradeName="Hasty End"
	UpgradeDescription(0)="Demolitionist weapon fire rate +5%."
	UpgradeDescription(1)="Demolitionist weapon fire rate +10%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_HastyEnd"
}