// Wrapper for ZedternalReborn.WMUpgrade_Perk_FieldMedic
class DKWrapper_Perk_FieldMedic extends WMUpgrade_Perk_FieldMedic
	config(ZedternalUnlimited);

var config float Cfg_HealRate;
var config float Cfg_Health;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_HealRate = 0.2f;
		default.Cfg_Health = 0.05f;
		default.Cfg_Damage = 0.05f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_FieldMedic') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_FieldMedic'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * FMin(default.Cfg_Health * upgLevel, 0.5f));
}

static simulated function ModifyHealerRechargeTime(out float InRechargeTime, float DefaultRechargeTime, int upgLevel)
{
	local float Fb_HealRate;

	Fb_HealRate = default.Cfg_HealRate;
	if (Fb_HealRate == 0)
		Fb_HealRate = default.HealRate;
	InRechargeTime = DefaultRechargeTime / (DefaultRechargeTime / InRechargeTime + Fb_HealRate * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_FieldMedic"
}
