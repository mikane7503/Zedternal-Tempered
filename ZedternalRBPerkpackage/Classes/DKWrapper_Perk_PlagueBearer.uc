// Wrapper for HowdyZTRExt.ZRUpgrade_Perk_PlagueBearer
class DKWrapper_Perk_PlagueBearer extends ZRUpgrade_Perk_PlagueBearer
	config(ZedternalUnlimited);

var config array<float> Cfg_DamageOverTime;
var config float Cfg_Damage;
var config float Cfg_MagSize;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageOverTime[0] = 0.1f;
		default.Cfg_Damage = 0.10f;
		default.Cfg_MagSize = 0.05f;

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

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Toxic'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	local float Fb_MagSize;

	Fb_MagSize = default.Cfg_MagSize;
	if (Fb_MagSize == 0)
		Fb_MagSize = default.MagSize;
	magazineCapacityFactor += Fb_MagSize * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_PlagueBearer"
}
