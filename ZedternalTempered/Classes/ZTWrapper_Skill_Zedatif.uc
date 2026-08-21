// Wrapper for ZedternalReborn.WMUpgrade_Skill_Zedatif
class ZTWrapper_Skill_Zedatif extends WMUpgrade_Skill_Zedatif config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config float Cfg_Snare;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.25f;
		default.Cfg_Bonus[1] = 0.6f;
		default.Cfg_Snare = 30.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Bonus.Length = 2;
		default.Cfg_Bonus[0] = 0.250000f;
		default.Cfg_Bonus[1] = 0.600000f;
		default.Cfg_Snare = 15.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifySnarePower(out float InSnarePower, float DefaultSnarePower, int upgLevel, optional class<DamageType> DamageType, optional byte BodyPart)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Toxic'))
		InSnarePower += DefaultSnarePower * default.Cfg_Snare;
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Toxic'))
		InDamage += int(float(DefaultDamage) * default.Cfg_Bonus[upgLevel - 1]);
}

static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	InHealAmount += DefaultHealAmount * default.Cfg_Bonus[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Zedatif"
}
