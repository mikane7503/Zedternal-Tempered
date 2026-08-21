// Wrapper for ZedternalReborn.WMUpgrade_Skill_Combustion
class ZTWrapper_Skill_Combustion extends WMUpgrade_Skill_Combustion config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.25f;
		default.Cfg_Damage[1] = 0.60f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.150000f;
		default.Cfg_Damage[1] = 0.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Freeze')))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1] * upgLevel);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Combustion"
}
