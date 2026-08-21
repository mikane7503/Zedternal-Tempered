class ZTUpgrade_Skill_RecycledFuse extends ZTUpgrade_Skill;
static simulated function ModifyMagSizeAndNumber(out int A,int Base,int L,KFWeapon W,optional array<class<KFPerk> > P,optional bool S=false,optional name N){if(class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,None))A+=Round(float(Base)*(L==1?0.10:0.20));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_RecycledFuse"
	UpgradeName="Recycled Fuse"
	UpgradeDescription(0)="Demolitionist weapon magazine capacity +10%."
	UpgradeDescription(1)="Demolitionist weapon magazine capacity +20%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_RecycledFuse"
}