// Wrapper for ZedternalReborn.WMUpgrade_Perk_Survivalist
class DKWrapper_Perk_Survivalist extends WMUpgrade_Perk_Survivalist
	config(ZedternalUnlimited);

var config float Cfg_SpareAmmo;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SpareAmmo = 0.2f;
		default.Cfg_Damage = 0.03f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor += default.Cfg_Damage * upgLevel;
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	local float Fb_SpareAmmo;

	Fb_SpareAmmo = default.Cfg_SpareAmmo;
	if (Fb_SpareAmmo == 0)
		Fb_SpareAmmo = default.SpareAmmo;
	spareAmmoFactor += Fb_SpareAmmo * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Survivalist"
}
