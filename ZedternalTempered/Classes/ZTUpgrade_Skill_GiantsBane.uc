class ZTUpgrade_Skill_GiantsBane extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> Damage;
var config array<float> MagSize;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Damage.Length = 2;
		default.Damage[0] = 0.200000f;
		default.Damage[1] = 0.400000f;
		default.MagSize.Length = 2;
		default.MagSize[0] = 0.300000f;
		default.MagSize[1] = 0.600000f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM != None && MyKFPM.bLargeZed)
		InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity,
	int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW,
	optional array<class<KFPerk> > WeaponPerkClass, optional bool bSecondary,
	optional name WeaponClassName)
{
	InMagazineCapacity += Round(float(DefaultMagazineCapacity)
		* default.MagSize[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Giantsbane"
	UpgradeName="Giantsbane"
	UpgradeDescription(0)="Deal <font color=\"#15d7fa\">20%</font> more damage to large zeds and gain <font color=\"#0bf1f1\">30%</font> magazine size."
	UpgradeDescription(1)="Deal <font color=\"#15d7fa\">40%</font> more damage to large zeds and gain <font color=\"#0bf1f1\">60%</font> magazine size."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Giantsbane'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Giantsbane_Deluxe'
	Name="Default__ZTUpgrade_Skill_GiantsBane"
}
