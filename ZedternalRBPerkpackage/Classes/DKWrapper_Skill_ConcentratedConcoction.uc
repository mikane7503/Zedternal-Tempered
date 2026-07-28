// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ConcentratedConcoction
class DKWrapper_Skill_ConcentratedConcoction extends ZRUpgrade_Skill_ConcentratedConcoction
	config(ZedternalUnlimited);

var config array<float> Cfg_DamageOverTime;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageOverTime[0] = 2.0f;
		default.Cfg_DamageOverTime[1] = 5.0f;
		default.Cfg_Damage[0] = 0.1f;
		default.Cfg_Damage[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	InDoTScaler += DefaultDotScaler * default.Cfg_DamageOverTime[upgLevel - 1];
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Freeze') || ClassIsChildOf(DamageType, class'KFDT_EMP') || ClassIsChildOf(DamageType, class'KFDT_Bleeding') || ClassIsChildOf(DamageType, class'ZRDT_ChargedRounds_DoT') || ClassIsChildOf(DamageType, class'ZRDT_laceratingRounds_DoT')))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1] * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ConcentratedConcoction"
}
