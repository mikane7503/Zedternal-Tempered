class ZTUpgrade_Skill_LargeCollapse extends ZTUpgrade_Skill;
static function ModifyDamageGiven(out int D,int Base,int L,optional Actor C,optional KFPawn_Monster M,optional KFPlayerController PC,optional class<KFDamageType> DT,optional int H,optional KFWeapon W){if(M!=None&&M.bLargeZed&&class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,DT))D+=Round(float(Base)*(L==1?0.10:0.20));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_LargeCollapse"
	UpgradeName="Large Collapse"
	UpgradeDescription(0)="Explosive damage to large zeds +10%."
	UpgradeDescription(1)="Explosive damage to large zeds +20%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_LargeCollapse"
}