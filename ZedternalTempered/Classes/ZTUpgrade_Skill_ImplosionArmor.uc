class ZTUpgrade_Skill_ImplosionArmor extends ZTUpgrade_Skill;
static function ModifyDamageTaken(out int D,int Base,int L,KFPawn P,optional class<DamageType> DT,optional Controller I,optional KFWeapon W){if(class<KFDamageType>(DT)!=None&&IsDamageTypeOnSpecificPerk(class<KFDamageType>(DT),class'KFGame.KFPerk_Demolitionist'))D-=Round(float(Base)*(L==1?0.10:0.20));}
defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ImplosionArmor"
	UpgradeName="Implosion Armor"
	UpgradeDescription(0)="Explosive damage taken -10%."
	UpgradeDescription(1)="Explosive damage taken -20%."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_HollowCaliber_Deluxe'
	Name="Default__ZTUpgrade_Skill_ImplosionArmor"
}