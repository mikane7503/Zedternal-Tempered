class ZTUpgrade_Skill_VoidStockpile extends ZTUpgrade_Skill;
static simulated function ModifySpareAmmoAmount(out int A,int Base,int L,KFWeapon W,optional const out STraderItem T,optional bool S=false){if(class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,None))A+=Round(float(Base)*(L==1?0.15:0.30));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_VoidStockpile"
	UpgradeName="Void Stockpile"
	UpgradeDescription(0)="Demolitionist weapon spare ammo +15%."
	UpgradeDescription(1)="Demolitionist weapon spare ammo +30%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_VoidStockpile"
}