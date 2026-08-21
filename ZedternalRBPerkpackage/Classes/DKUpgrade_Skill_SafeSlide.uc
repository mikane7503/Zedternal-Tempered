// Safe Slide - universal: fall damage reduction / immunity.
class DKUpgrade_Skill_SafeSlide extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> FallResist;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.FallResist[0] = 0.60f;
		default.FallResist[1] = 1.00f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'KFDT_Falling'))
		return;

	InDamage -= Round(float(DefaultDamage) * default.FallResist[upgLevel - 1]);
	if (InDamage < 0)
		InDamage = 0;
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_SafeSlide"

	UpgradeName="Safe Slide"
	upgradeDescription(0)="Take <font color=\"#77d914\">60% less</font> <font color=\"#15d7fa\">fall damage</font>."
	upgradeDescription(1)="Take <font color=\"#77d914\">no</font> <font color=\"#15d7fa\">fall damage</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SafeSlide'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SafeSlide_Deluxe'
	Name="Default__DKUpgrade_Skill_SafeSlide"
}
