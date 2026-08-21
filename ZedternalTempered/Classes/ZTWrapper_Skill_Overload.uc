// Wrapper for ZedternalReborn.WMUpgrade_Skill_Overload
class ZTWrapper_Skill_Overload extends WMUpgrade_Skill_Overload config(ZedternalUnlimited);

var config array<float> Cfg_MagCapacity;
var config array<float> Cfg_MaxAmmo;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MagCapacity[0] = 0.2f;
		default.Cfg_MagCapacity[1] = 0.5f;
		default.Cfg_MaxAmmo[0] = 0.2f;
		default.Cfg_MaxAmmo[1] = 0.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MagCapacity.Length = 2;
		default.Cfg_MagCapacity[0] = 0.200000f;
		default.Cfg_MagCapacity[1] = 0.500000f;
		default.Cfg_MaxAmmo.Length = 2;
		default.Cfg_MaxAmmo[0] = 0.200000f;
		default.Cfg_MaxAmmo[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	local float Fb_MagCapacity;

	if (default.Cfg_MagCapacity.Length > 0 && default.Cfg_MagCapacity[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_MagCapacity.Length > 1)
			Fb_MagCapacity = default.Cfg_MagCapacity[1];
		else
			Fb_MagCapacity = default.Cfg_MagCapacity[0];
	}
	else
	{
		if (upgLevel > 1 && default.MagCapacity.Length > 1)
			Fb_MagCapacity = default.MagCapacity[1];
		else
			Fb_MagCapacity = default.MagCapacity[0];
	}
	magazineCapacityFactor += Fb_MagCapacity;
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
	Name="Default__ZTWrapper_Skill_Overload"
}
