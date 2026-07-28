// Wrapper for ZedternalReborn.WMUpgrade_Perk_SWAT
class DKWrapper_Perk_SWAT extends WMUpgrade_Perk_SWAT
	config(ZedternalUnlimited);

var config float Cfg_Armor;
var config float Cfg_Damage;
var config float Cfg_MagSize;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor = 0.1f;
		default.Cfg_Damage = 0.05f;
		default.Cfg_MagSize = 0.1f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Swat') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Swat'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += Round(float(DefaultArmor) * FMin(default.Cfg_Armor * upgLevel, 1.0f));
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
	Name="Default__DKWrapper_Perk_SWAT"
}
