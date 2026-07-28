// Jekyll skill - Cold Calculation: big damage spike during ZED-time while NOT transformed.
class DKUpgrade_Skill_ColdCalculation extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Damage[0] = 0.20f;  default.Damage[1] = 0.40f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	if (DamageInstigator.WorldInfo == None || DamageInstigator.WorldInfo.TimeDilation >= 1.0f)
		return;   // only during zed-time

	H = class'DKUpgrade_Perk_JekyllHyde'.static.FindHelper(DamageInstigator.Pawn);
	if (H != None && H.bHyde)
		return;

	InDamage += Round(float(DefaultDamage) * default.Damage[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_ColdCalculation"
	UpgradeName="Cold Calculation"
	upgradeDescription(0)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, deal <font color=\"#ff3399\">+20%</font> damage during <font color=\"#15d7fa\">ZED-time</font>."
	upgradeDescription(1)="As <font color=\"#15d7fa\">Dr. Jekyll</font>, deal <font color=\"#ff3399\">+40%</font> damage during <font color=\"#15d7fa\">ZED-time</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ColdCalculation'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ColdCalculation_Deluxe'
	Name="Default__DKUpgrade_Skill_ColdCalculation"
}
