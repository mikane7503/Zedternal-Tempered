// Wrapper for ZedternalReborn.WMUpgrade_Skill_AmmoPickup
class ZTWrapper_Skill_AmmoPickup extends WMUpgrade_Skill_AmmoPickup config(ZedternalUnlimited);

var config array<float> Cfg_Ammo;
var config int MODEVERSION;

const SLOT_Ammo_0 = 1;
const SLOT_Ammo_1 = 2;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Ammo[0] = 1.5f;
		default.Cfg_Ammo[1] = 2.25f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Ammo.Length = 2;
		default.Cfg_Ammo[0] = 1.500000f;
		default.Cfg_Ammo[1] = 2.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[1] = default.Cfg_Ammo[0];
	H.Values[2] = default.Cfg_Ammo[1];
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTBalanceRepHelper H;
	local float Val_Ammo_0;
	local float Val_Ammo_1;
	local float Resolved_Ammo;
	local byte i;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[1] != 0.0f)
		Val_Ammo_0 = H.Values[1];
	else
		Val_Ammo_0 = default.Ammo[0];
	if (H != None && H.Values[2] != 0.0f)
		Val_Ammo_1 = H.Values[2];
	else
		Val_Ammo_1 = default.Ammo[1];
	if (upgLevel > 1)
		Resolved_Ammo = Val_Ammo_1;
	else
		Resolved_Ammo = Val_Ammo_0;
	if (KFW != None)
	{
		for (i = 0; i <= 1; ++i)
		{
			KFW.AmmoPickupScale[i] = KFW.default.AmmoPickupScale[i] * Resolved_Ammo;
		}
	}

	if (KFWeap_Thrown_C4(KFW) != None)
		KFW.AmmoPickupScale[0] = FCeil(KFW.AmmoPickupScale[0]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_AmmoPickup"
}
