// Wrapper for HowdyZTRExt.ZRUpgrade_Perk_Vampire
class DKWrapper_Perk_Vampire extends ZRUpgrade_Perk_Vampire
	config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config float Cfg_Health;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed = 0.04f;
		default.Cfg_Health = 0.05f;
		default.Cfg_Damage = 0.05f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * FMin(default.Cfg_Health * upgLevel, 0.5f));
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Bleeding'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local float Fb_MoveSpeed;

	Fb_MoveSpeed = default.Cfg_MoveSpeed;
	if (Fb_MoveSpeed == 0)
		Fb_MoveSpeed = default.MoveSpeed;
	speedFactor += Fb_MoveSpeed * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Vampire"
}
