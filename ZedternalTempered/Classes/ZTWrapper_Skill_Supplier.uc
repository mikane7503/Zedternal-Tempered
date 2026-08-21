// Wrapper for ZedternalReborn.WMUpgrade_Skill_Supplier
class ZTWrapper_Skill_Supplier extends WMUpgrade_Skill_Supplier config(ZedternalUnlimited);

var config float Cfg_SupplierAmmo;
var config array<float> Cfg_MaxAmmo;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SupplierAmmo = 0.3f;;
		default.Cfg_MaxAmmo[0] = 0.3f;
		default.Cfg_MaxAmmo[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_SupplierAmmo = 0.300000f;
		default.Cfg_MaxAmmo.Length = 2;
		default.Cfg_MaxAmmo[0] = 0.300000f;
		default.Cfg_MaxAmmo[1] = 0.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function SupplierModifiers(int upgLevel, out float PrimaryAmmoPercentage, out float SecondaryAmmoPercentage, out float ArmorPercentage, out int GrenadeAmount)
{
	local float Fb_SupplierAmmo;

	Fb_SupplierAmmo = default.Cfg_SupplierAmmo;
	if (Fb_SupplierAmmo == 0)
		Fb_SupplierAmmo = default.SupplierAmmo;
	PrimaryAmmoPercentage += Fb_SupplierAmmo;
	SecondaryAmmoPercentage += Fb_SupplierAmmo;
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	local float Fb_MaxAmmo;

	if (default.Cfg_MaxAmmo.Length > 0 && default.Cfg_MaxAmmo[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MaxAmmo.Length > 1)
			Fb_MaxAmmo = default.Cfg_MaxAmmo[1];
		else
			Fb_MaxAmmo = default.Cfg_MaxAmmo[0];
	}
	else
	{
		if (upgLevel > 1 && default.MaxAmmo.Length > 1)
			Fb_MaxAmmo = default.MaxAmmo[1];
		else
			Fb_MaxAmmo = default.MaxAmmo[0];
	}
	spareAmmoFactor += Fb_MaxAmmo;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Supplier"
}
