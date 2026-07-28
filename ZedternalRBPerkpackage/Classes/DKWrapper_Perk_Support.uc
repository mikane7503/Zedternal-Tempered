// Wrapper for ZedternalReborn.WMUpgrade_Perk_Support
class DKWrapper_Perk_Support extends WMUpgrade_Perk_Support
	config(ZedternalUnlimited);

var config float Cfg_StoppingPower;
var config float Cfg_Damage;
var config float Cfg_Penetration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_StoppingPower = 0.1f;
		default.Cfg_Damage = 0.05f;
		default.Cfg_Penetration = 0.35f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Support') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Support'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyStumblePowerPassive(out float stumblePowerFactor, int upgLevel)
{
	stumblePowerFactor += default.Cfg_StoppingPower * upgLevel;
}

static function ModifyKnockdownPowerPassive(out float knockdownPowerFactor, int upgLevel)
{
	knockdownPowerFactor += default.Cfg_StoppingPower * upgLevel;
}

static simulated function ModifyPenetrationPassive(out float penetrationFactor, int upgLevel)
{
	local float Fb_Penetration;

	Fb_Penetration = default.Cfg_Penetration;
	if (Fb_Penetration == 0)
		Fb_Penetration = default.Penetration;
	penetrationFactor += Fb_Penetration * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Support"
}
