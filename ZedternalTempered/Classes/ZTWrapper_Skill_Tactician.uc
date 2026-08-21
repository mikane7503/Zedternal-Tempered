// Wrapper for ZedternalReborn.WMUpgrade_Skill_Tactician
class ZTWrapper_Skill_Tactician extends WMUpgrade_Skill_Tactician config(ZedternalUnlimited);

var config array<float> Cfg_Mod;
var config int MODEVERSION;

const SLOT_Mod_0 = 42;
const SLOT_Mod_1 = 43;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Mod[0] = 1.0f;
		default.Cfg_Mod[1] = 1.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Mod.Length = 2;
		default.Cfg_Mod[0] = 1.000000f;
		default.Cfg_Mod[1] = 1.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[42] = default.Cfg_Mod[0];
	H.Values[43] = default.Cfg_Mod[1];
}

static simulated function GetZedTimeModifier(out float InModifier, int upgLevel, KFWeapon KFW)
{
	local ZTBalanceRepHelper H;
	local float Val_Mod_0;
	local float Val_Mod_1;
	local float Resolved_Mod;
	local name StateName;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[42] != 0.0f)
		Val_Mod_0 = H.Values[42];
	else
		Val_Mod_0 = default.Mod[0];
	if (H != None && H.Values[43] != 0.0f)
		Val_Mod_1 = H.Values[43];
	else
		Val_Mod_1 = default.Mod[1];
	if (upgLevel > 1)
		Resolved_Mod = Val_Mod_1;
	else
		Resolved_Mod = Val_Mod_0;
	StateName = KFW.GetStateName();

	if (class'ZedternalReborn.WMWeaponStates'.static.IsWeaponReloadState(StateName) || class'ZedternalReborn.WMWeaponStates'.static.IsWeaponSwitchState(StateName))
		InModifier += Resolved_Mod;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Tactician"
}
