// Wrapper for ZedternalReborn.WMUpgrade_Skill_Napalm
class DKWrapper_Skill_Napalm extends WMUpgrade_Skill_Napalm
	config(ZedternalUnlimited);

var config float Cfg_MaxDamage;
var config array<float> Cfg_DamageFactor;
var config float Cfg_MaxProbability;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MaxDamage = 75.0f;
		default.Cfg_DamageFactor[0] = 0.2f;
		default.Cfg_DamageFactor[1] = 0.5f;
		default.Cfg_MaxProbability = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.WMDT && DamageInstigator != None && MyKFPM != None && FRand() < (float(DefaultDamage) * default.Cfg_MaxProbability / default.Cfg_MaxDamage))
	{
		//add fire/microwave effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.Cfg_DamageFactor[upgLevel - 1]), DamageInstigator, default.WMDT);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Napalm"
}
