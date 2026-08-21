// Wrapper for ZedternalReborn.WMUpgrade_Skill_Hemoglobin
class ZTWrapper_Skill_Hemoglobin extends WMUpgrade_Skill_Hemoglobin config(ZedternalUnlimited);

var config array<int> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 10;
		default.Cfg_Damage[1] = 50;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 30;
		default.Cfg_Damage[1] = 100;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Toxic') && DamageInstigator != None && MyKFPM != None && !MyKFPM.bIsPoisoned)
	{
		//add poison effects on zed
		MyKFPM.TakeDamage(default.Cfg_Damage[upgLevel - 1], DamageInstigator, MyKFPM.Location, default.VectZero, default.WMDT);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Hemoglobin"
}
