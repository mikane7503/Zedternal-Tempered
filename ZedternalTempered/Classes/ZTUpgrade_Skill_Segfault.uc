// Segfault - universal glitch: executes. Bonus damage vs nearly-dead zeds.
class ZTUpgrade_Skill_Segfault extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ExecuteBonus;
var config float HealthThreshold;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ExecuteBonus[0] = 0.40f;
		default.ExecuteBonus[1] = 0.80f;
		default.HealthThreshold = 0.15f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM == None || MyKFPM.HealthMax <= 0)
		return;

	if (float(MyKFPM.Health) / float(MyKFPM.HealthMax) <= default.HealthThreshold)
		InDamage += Round(float(DefaultDamage) * default.ExecuteBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Segfault"

	UpgradeName="Segfault"
	upgradeDescription(0)="Deal <font color=\"#ff3399\">+40% damage</font> to zeds below <font color=\"#00ff00\">15% health</font>."
	upgradeDescription(1)="Deal <font color=\"#ff3399\">+80% damage</font> to zeds below <font color=\"#00ff00\">15% health</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Segfault'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Segfault_Deluxe'
	Name="Default__ZTUpgrade_Skill_Segfault"
}
