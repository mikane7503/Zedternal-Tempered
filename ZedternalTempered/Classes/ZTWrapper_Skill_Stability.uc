// Wrapper for ZedternalReborn.WMUpgrade_Skill_Stability
class ZTWrapper_Skill_Stability extends WMUpgrade_Skill_Stability config(ZedternalUnlimited);

var config array<float> Cfg_AimRecoil;
var config array<float> Cfg_HipRecoil;
var config int MODEVERSION;

const SLOT_AimRecoil_0 = 36;
const SLOT_AimRecoil_1 = 37;
const SLOT_HipRecoil_0 = 38;
const SLOT_HipRecoil_1 = 39;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_AimRecoil[0] = 0.25f;
		default.Cfg_AimRecoil[1] = 0.5f;
		default.Cfg_HipRecoil[0] = 0.5f;
		default.Cfg_HipRecoil[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_AimRecoil.Length = 2;
		default.Cfg_AimRecoil[0] = 0.250000f;
		default.Cfg_AimRecoil[1] = 0.500000f;
		default.Cfg_HipRecoil.Length = 2;
		default.Cfg_HipRecoil[0] = 0.500000f;
		default.Cfg_HipRecoil[1] = 0.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[36] = default.Cfg_AimRecoil[0];
	H.Values[37] = default.Cfg_AimRecoil[1];
	H.Values[38] = default.Cfg_HipRecoil[0];
	H.Values[39] = default.Cfg_HipRecoil[1];
}

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	local ZTBalanceRepHelper H;
	local float Val_AimRecoil_0;
	local float Val_AimRecoil_1;
	local float Resolved_AimRecoil;
	local float Val_HipRecoil_0;
	local float Val_HipRecoil_1;
	local float Resolved_HipRecoil;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[36] != 0.0f)
		Val_AimRecoil_0 = H.Values[36];
	else
		Val_AimRecoil_0 = default.AimRecoil[0];
	if (H != None && H.Values[37] != 0.0f)
		Val_AimRecoil_1 = H.Values[37];
	else
		Val_AimRecoil_1 = default.AimRecoil[1];
	if (upgLevel > 1)
		Resolved_AimRecoil = Val_AimRecoil_1;
	else
		Resolved_AimRecoil = Val_AimRecoil_0;
	if (H != None && H.Values[38] != 0.0f)
		Val_HipRecoil_0 = H.Values[38];
	else
		Val_HipRecoil_0 = default.HipRecoil[0];
	if (H != None && H.Values[39] != 0.0f)
		Val_HipRecoil_1 = H.Values[39];
	else
		Val_HipRecoil_1 = default.HipRecoil[1];
	if (upgLevel > 1)
		Resolved_HipRecoil = Val_HipRecoil_1;
	else
		Resolved_HipRecoil = Val_HipRecoil_0;
	if (KFW != None)
	{
		if (KFW.bUsingSights)
			InRecoilModifier -= DefaultRecoilModifier * Resolved_AimRecoil;
		else
			InRecoilModifier -= DefaultRecoilModifier * Resolved_HipRecoil;
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Stability"
}
