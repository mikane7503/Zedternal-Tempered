// Wrapper for ZedternalReborn.WMUpgrade_Skill_ExtraRounds
class ZTWrapper_Skill_ExtraRounds extends WMUpgrade_Skill_ExtraRounds config(ZedternalUnlimited);

var config array<float> Cfg_ExtraAmmoPrct;
var config array<int> Cfg_ExtraAmmo;
var config int MODEVERSION;

const SLOT_ExtraAmmo_0 = 9;
const SLOT_ExtraAmmo_1 = 10;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ExtraAmmoPrct[0] = 0.15f;
		default.Cfg_ExtraAmmoPrct[1] = 0.4f;
		default.Cfg_ExtraAmmo[0] = 5;
		default.Cfg_ExtraAmmo[1] = 10;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_ExtraAmmoPrct.Length = 2;
		default.Cfg_ExtraAmmoPrct[0] = 0.150000f;
		default.Cfg_ExtraAmmoPrct[1] = 0.400000f;
		default.Cfg_ExtraAmmo.Length = 2;
		default.Cfg_ExtraAmmo[0] = 5;
		default.Cfg_ExtraAmmo[1] = 10;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[9] = default.Cfg_ExtraAmmo[0];
	H.Values[10] = default.Cfg_ExtraAmmo[1];
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	local float Fb_ExtraAmmoPrct;

	if (default.Cfg_ExtraAmmoPrct.Length > 0 && default.Cfg_ExtraAmmoPrct[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_ExtraAmmoPrct.Length > 1)
			Fb_ExtraAmmoPrct = default.Cfg_ExtraAmmoPrct[1];
		else
			Fb_ExtraAmmoPrct = default.Cfg_ExtraAmmoPrct[0];
	}
	else
	{
		if (upgLevel > 1 && default.ExtraAmmoPrct.Length > 1)
			Fb_ExtraAmmoPrct = default.ExtraAmmoPrct[1];
		else
			Fb_ExtraAmmoPrct = default.ExtraAmmoPrct[0];
	}
	spareAmmoFactor += Fb_ExtraAmmoPrct;
}

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
	local ZTBalanceRepHelper H;
	local int Val_ExtraAmmo_0;
	local int Val_ExtraAmmo_1;
	local int Resolved_ExtraAmmo;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[9] != 0.0f)
		Val_ExtraAmmo_0 = H.Values[9];
	else
		Val_ExtraAmmo_0 = default.ExtraAmmo[0];
	if (H != None && H.Values[10] != 0.0f)
		Val_ExtraAmmo_1 = H.Values[10];
	else
		Val_ExtraAmmo_1 = default.ExtraAmmo[1];
	if (upgLevel > 1)
		Resolved_ExtraAmmo = Val_ExtraAmmo_1;
	else
		Resolved_ExtraAmmo = Val_ExtraAmmo_0;
	if (IsWeaponOnSpecificPerk(KFW, class'KFPerk_Demolitionist'))
		InSpareAmmo += Resolved_ExtraAmmo;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_ExtraRounds"
}
