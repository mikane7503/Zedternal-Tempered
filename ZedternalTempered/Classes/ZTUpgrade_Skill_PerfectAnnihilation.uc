class ZTUpgrade_Skill_PerfectAnnihilation extends ZTUpgrade_Skill;
static function ModifyDamageGiven(out int D,int Base,int L,optional Actor C,optional KFPawn_Monster M,optional KFPlayerController PC,optional class<KFDamageType> DT,optional int H,optional KFWeapon W){if(M!=None&&M.Class.static.IsABoss()&&class'ZTUpgrade_Perk_Hollow'.static.IsDemolitionDamage(W,DT))D+=Round(float(Base)*(L==1?0.15:0.30));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_PerfectAnnihilation"
	UpgradeName="Perfect Annihilation"
	UpgradeDescription(0)="Explosive damage to bosses +15%."
	UpgradeDescription(1)="Explosive damage to bosses +30%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_PerfectAnnihilation"
}