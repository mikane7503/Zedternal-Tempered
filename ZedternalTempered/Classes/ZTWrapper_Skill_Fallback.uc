// Wrapper for ZedternalReborn.WMUpgrade_Skill_Fallback
class ZTWrapper_Skill_Fallback extends WMUpgrade_Skill_Fallback config(ZedternalUnlimited);

var config array<int> Cfg_ExtraGrenades;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ExtraGrenades[0] = 3;
		default.Cfg_ExtraGrenades[1] = 6;
		default.Cfg_Damage[0] = 1.0f;
		default.Cfg_Damage[1] = 2.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_ExtraGrenades.Length = 2;
		default.Cfg_ExtraGrenades[0] = 3;
		default.Cfg_ExtraGrenades[1] = 6;
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 1.000000f;
		default.Cfg_Damage[1] = 2.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponSidearmOrKnife(MyKFW))
		InDamage += DefaultDamage * default.Cfg_Damage[upgLevel - 1];
}

static simulated function ModifySpareGrenadeAmount(out int SpareGrenade, int DefaultSpareGrenade, int upgLevel)
{
	local int Fb_ExtraGrenades;

	if (default.Cfg_ExtraGrenades.Length > 0 && default.Cfg_ExtraGrenades[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_ExtraGrenades.Length > 1)
			Fb_ExtraGrenades = default.Cfg_ExtraGrenades[1];
		else
			Fb_ExtraGrenades = default.Cfg_ExtraGrenades[0];
	}
	else
	{
		if (upgLevel > 1 && default.ExtraGrenades.Length > 1)
			Fb_ExtraGrenades = default.ExtraGrenades[1];
		else
			Fb_ExtraGrenades = default.ExtraGrenades[0];
	}
	SpareGrenade += Fb_ExtraGrenades;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Fallback"
}
