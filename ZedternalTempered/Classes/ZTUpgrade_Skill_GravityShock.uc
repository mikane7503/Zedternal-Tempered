class ZTUpgrade_Skill_GravityShock extends ZTUpgrade_Skill;
static function ModifyStumblePower(out float V,float Base,int L,optional KFPawn P,optional class<KFDamageType> DT,optional out float CD,optional byte BP,optional KFPawn O){if(DT!=None&&IsDamageTypeOnSpecificPerk(DT,class'KFGame.KFPerk_Demolitionist'))V+=Base*(L==1?0.20:0.40);}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_GravityShock"
	UpgradeName="Gravity Shock"
	UpgradeDescription(0)="Explosive stumble power +20%."
	UpgradeDescription(1)="Explosive stumble power +40%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_GravityShock"
}