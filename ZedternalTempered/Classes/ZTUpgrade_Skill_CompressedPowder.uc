class ZTUpgrade_Skill_CompressedPowder extends ZTUpgrade_Skill;
static function ModifyDamageGiven(out int D,int Base,int L,optional Actor C,optional KFPawn_Monster M,optional KFPlayerController PC,optional class<KFDamageType> DT,optional int H,optional KFWeapon W){if(class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,DT))D+=Round(float(Base)*(L==1?0.05:0.10));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_CompressedPowder"
	UpgradeName="Compressed Powder"
	UpgradeDescription(0)="Demolitionist explosive damage +5%."
	UpgradeDescription(1)="Demolitionist explosive damage +10%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_CompressedPowder"
}