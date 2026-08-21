// Wrapper for ZedternalReborn.WMUpgrade_Skill_AcidicRounds
class ZTWrapper_Skill_AcidicRounds extends WMUpgrade_Skill_AcidicRounds config(ZedternalUnlimited);

var config float Cfg_maxDamage;
var config array<float> Cfg_damageFactor;
var config float Cfg_maxProbability;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_maxDamage = 75.0f;
		default.Cfg_damageFactor[0] = 0.2f;
		default.Cfg_damageFactor[1] = 0.5f;
		default.Cfg_maxProbability = 1.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_maxDamage = 75.000000f;
		default.Cfg_damageFactor.Length = 2;
		default.Cfg_damageFactor[0] = 0.200000f;
		default.Cfg_damageFactor[1] = 0.500000f;
		default.Cfg_maxProbability = 1.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.WMDT && DamageInstigator != None && MyKFPM != None && !MyKFPM.bIsPoisoned && FRand() < (float(DefaultDamage) * default.Cfg_maxProbability / default.Cfg_maxDamage))
	{
		//add poison effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.Cfg_damageFactor[upgLevel - 1]), DamageInstigator, default.WMDT);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_AcidicRounds"
}
