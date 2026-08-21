class ZUTUpgrade_Skill_BerserkerRage extends ZUTUpgrade_Skill_Base;

var array<float> Damage, MeleeDamage;

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageInstigator != None && DamageInstigator.Pawn != None && WMPawn_Human(DamageInstigator.Pawn) != None && WMPawn_Human(DamageInstigator.Pawn).ZedternalArmor <= 0)
	{
		if (DamageType != None && static.IsMeleeDamageType(DamageType))
			InDamage += Round(float(DefaultDamage) * default.MeleeDamage[upgLevel - 1]);
		else
			InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
	}
}

defaultproperties
{
	MeleeDamage(0)=0.10f
	MeleeDamage(1)=0.20f
	Damage(0)=0.05f
	Damage(1)=0.10f

	bShouldLocalize=True
	UpgradeName="ZedternalReborn.WMUpgrade_Skill_BerserkerRage"
	UpgradeIcon(0)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BerserkerRage'
	UpgradeIcon(1)=Texture2D'ZedternalReborn_Resource.Skills.UI_Skill_BerserkerRage_Deluxe'

	Name="Default__ZUTUpgrade_Skill_BerserkerRage"
}
