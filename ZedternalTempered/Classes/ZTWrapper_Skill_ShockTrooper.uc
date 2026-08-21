// Wrapper for ZedternalReborn.WMUpgrade_Skill_ShockTrooper
class ZTWrapper_Skill_ShockTrooper extends WMUpgrade_Skill_ShockTrooper config(ZedternalUnlimited);

var config array<float> Cfg_ReloadSpeed;
var config int MODEVERSION;

const SLOT_ReloadSpeed_0 = 20;
const SLOT_ReloadSpeed_1 = 21;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadSpeed[0] = 0.4f;
		default.Cfg_ReloadSpeed[1] = 1.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_ReloadSpeed.Length = 2;
		default.Cfg_ReloadSpeed[0] = 0.200000f;
		default.Cfg_ReloadSpeed[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[20] = default.Cfg_ReloadSpeed[0];
	H.Values[21] = default.Cfg_ReloadSpeed[1];
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTBalanceRepHelper H;
	local float Val_ReloadSpeed_0;
	local float Val_ReloadSpeed_1;
	local float Resolved_ReloadSpeed;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[20] != 0.0f)
		Val_ReloadSpeed_0 = H.Values[20];
	else
		Val_ReloadSpeed_0 = default.ReloadSpeed[0];
	if (H != None && H.Values[21] != 0.0f)
		Val_ReloadSpeed_1 = H.Values[21];
	else
		Val_ReloadSpeed_1 = default.ReloadSpeed[1];
	if (upgLevel > 1)
		Resolved_ReloadSpeed = Val_ReloadSpeed_1;
	else
		Resolved_ReloadSpeed = Val_ReloadSpeed_0;
	if (KFW != None && KFW.AmmoCount[0] == 0)
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Resolved_ReloadSpeed);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_ShockTrooper"
}
