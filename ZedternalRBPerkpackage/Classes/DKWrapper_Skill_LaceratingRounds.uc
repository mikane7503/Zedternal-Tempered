// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_LaceratingRounds
class DKWrapper_Skill_LaceratingRounds extends ZRUpgrade_Skill_LaceratingRounds
	config(ZedternalUnlimited);

var config float Cfg_maxDamage;
var config array<float> Cfg_damageFactor;
var config float Cfg_maxProbability;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_maxDamage = 75.0f;
		default.Cfg_damageFactor[0] = 0.3f;
		default.Cfg_damageFactor[1] = 0.6f;
		default.Cfg_maxProbability = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.ZRDT && DamageInstigator != None && MyKFPM != None && FRand() < (float(DefaultDamage) * default.Cfg_maxProbability / default.Cfg_maxDamage))
	{
		//add poison effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.Cfg_damageFactor[upgLevel - 1]), DamageInstigator, default.ZRDT);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_LaceratingRounds"
}
