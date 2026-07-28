// Wrapper for HowdyZTRExt.ZRUpgrade_Perk_Scientist
class DKWrapper_Perk_Scientist extends ZRUpgrade_Perk_Scientist
	config(ZedternalUnlimited);

var config float Cfg_Defense;
var config array<float> Cfg_DamageOverTime;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Defense = 0.03f;
		default.Cfg_DamageOverTime[0] = 0.2f;
		default.Cfg_Damage = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDoTScaler(out float InDoTScaler, float DefaultDotScaler, int upgLevel, optional class<KFDamageType> KFDT, optional bool bNapalmInfected)
{
	InDoTScaler += DefaultDotScaler * default.Cfg_DamageOverTime[upgLevel - 1];
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_EMP') || ClassIsChildOf(DamageType, class'KFDT_Freeze') || ClassIsChildOf(DamageType, class'KFDT_Sonic'))
		InDamage -= Round(float(DefaultDamage) * FMin(default.Cfg_Defense * upgLevel, 0.4f));
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Freeze') || ClassIsChildOf(DamageType, class'KFDT_EMP') || ClassIsChildOf(DamageType, class'KFDT_Bleeding') || ClassIsChildOf(DamageType, class'ZRDT_ChargedRounds_DoT') || ClassIsChildOf(DamageType, class'ZRDT_laceratingRounds_DoT')))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Scientist"
}
