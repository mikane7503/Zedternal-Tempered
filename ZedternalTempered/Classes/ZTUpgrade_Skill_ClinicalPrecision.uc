// Jekyll skill - Clinical Precision: bonus headshot damage while NOT transformed.
class ZTUpgrade_Skill_ClinicalPrecision extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> HeadDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HeadDamage[0] = 0.25f;  default.HeadDamage[1] = 0.45f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	if (HitZoneIdx != HZI_Head)
		return;

	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(DamageInstigator.Pawn);
	if (H != None && H.bHyde)
		return;

	InDamage += Round(float(DefaultDamage) * default.HeadDamage[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ClinicalPrecision"
	UpgradeName="Clinical Precision"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, <font color=\"#66cc00\">headshots</font> deal <font color=\"#ff3399\">25%</font> more damage."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, <font color=\"#66cc00\">headshots</font> deal <font color=\"#ff3399\">45%</font> more damage."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ClinicalPrecision'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ClinicalPrecision_Deluxe'
	Name="Default__ZTUpgrade_Skill_ClinicalPrecision"
}
