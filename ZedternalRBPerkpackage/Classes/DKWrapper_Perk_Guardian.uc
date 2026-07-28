// Wrapper for HowdyZTRExt.ZRUpgrade_Perk_Guardian
class DKWrapper_Perk_Guardian extends ZRUpgrade_Perk_Guardian
	config(ZedternalUnlimited);

var config float Cfg_SpareAmmo;
var config float Cfg_Recoil;
var config float Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SpareAmmo = 0.10f;
		default.Cfg_Recoil = 0.10f;
		default.Cfg_Armor = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	//We have to limit our multiplier using FMin to make sure that its reflects the PerkBonus maxValue that we have defined.
	MaxArmor += Round(float(DefaultArmor) * default.Cfg_Armor * upgLevel);
}

static simulated function ModifyRecoilPassive(out float recoilFactor, int upgLevel)
{
	local float Fb_Recoil;

	Fb_Recoil = default.Cfg_Recoil;
	if (Fb_Recoil == 0)
		Fb_Recoil = default.Recoil;
	recoilFactor -= recoilFactor * FMin(Fb_Recoil * upgLevel, 0.8f);
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
	Name="Default__DKWrapper_Perk_Guardian"
}
