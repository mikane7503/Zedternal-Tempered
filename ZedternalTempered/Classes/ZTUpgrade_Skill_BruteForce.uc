// Hyde skill - Brute Force: even more melee damage while transformed.
class ZTUpgrade_Skill_BruteForce extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> MeleeBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MeleeBonus[0] = 0.50f;  default.MeleeBonus[1] = 1.00f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	if (!IsMeleeDamageType(DamageType))
		return;

	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(DamageInstigator.Pawn);
	if (H == None || !H.bHyde || H.bShockwaveActive)
		return;   // skip shockwave re-entry so it isn't double-buffed

	InDamage += Round(float(DefaultDamage) * default.MeleeBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_BruteForce"
	UpgradeName="Brute Force"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee deals an extra <font color=\"#ff3399\">+50%</font> damage."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee deals an extra <font color=\"#ff3399\">+100%</font> damage."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BruteForce'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BruteForce_Deluxe'
	Name="Default__ZTUpgrade_Skill_BruteForce"
}
