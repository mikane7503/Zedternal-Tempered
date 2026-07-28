// Wrapper for ZedternalReborn.WMUpgrade_Perk_Gunslinger
class DKWrapper_Perk_Gunslinger extends WMUpgrade_Perk_Gunslinger
	config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config float Cfg_SwitchSpeed;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed = 0.04f;
		default.Cfg_SwitchSpeed = 0.25f;
		default.Cfg_Damage = 0.05f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Gunslinger') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Gunslinger'))
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

static simulated function ModifyWeaponSwitchTimePassive(out float switchTimeFactor, int upgLevel)
{
	local float Fb_SwitchSpeed;

	Fb_SwitchSpeed = default.Cfg_SwitchSpeed;
	if (Fb_SwitchSpeed == 0)
		Fb_SwitchSpeed = default.SwitchSpeed;
	switchTimeFactor = 1.0f / (1.0f / switchTimeFactor + Fb_SwitchSpeed);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Gunslinger"
}
