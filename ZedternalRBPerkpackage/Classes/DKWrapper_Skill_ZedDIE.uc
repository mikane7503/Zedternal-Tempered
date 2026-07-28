// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ZedDIE
class DKWrapper_Skill_ZedDIE extends ZRUpgrade_Skill_ZedDIE
	config(ZedternalUnlimited);

var config array<float> Cfg_DamageOverTime;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageOverTime[0] = 1.5f;
		default.Cfg_DamageOverTime[1] = 3.0f;
		default.Cfg_Damage[0] = 0.30f;
		default.Cfg_Damage[1] = 0.60f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Toxic'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1] * upgLevel);
}

static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	InDoTScaler += DefaultDotScaler * default.Cfg_DamageOverTime[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ZedDIE"
}
