// Wrapper for ZedternalReborn.WMUpgrade_Skill_Pressure
class ZTWrapper_Skill_Pressure extends WMUpgrade_Skill_Pressure config(ZedternalUnlimited);

var config int Cfg_minHealth;
var config array<float> Cfg_maxReloadSpeed;
var config int MODEVERSION;

const SLOT_maxReloadSpeed_0 = 15;
const SLOT_maxReloadSpeed_1 = 16;
const SLOT_minHealth = 17;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_minHealth = 60;
		default.Cfg_maxReloadSpeed[0] = 0.6f;
		default.Cfg_maxReloadSpeed[1] = 1.5f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MinHealth = 60;
		default.Cfg_maxReloadSpeed.Length = 2;
		default.Cfg_maxReloadSpeed[0] = 0.300000f;
		default.Cfg_maxReloadSpeed[1] = 0.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[15] = default.Cfg_maxReloadSpeed[0];
	H.Values[16] = default.Cfg_maxReloadSpeed[1];
	H.Values[17] = default.Cfg_minHealth;
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTBalanceRepHelper H;
	local float Val_maxReloadSpeed_0;
	local float Val_maxReloadSpeed_1;
	local float Resolved_maxReloadSpeed;
	local int Val_minHealth;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[15] != 0.0f)
		Val_maxReloadSpeed_0 = H.Values[15];
	else
		Val_maxReloadSpeed_0 = default.maxReloadSpeed[0];
	if (H != None && H.Values[16] != 0.0f)
		Val_maxReloadSpeed_1 = H.Values[16];
	else
		Val_maxReloadSpeed_1 = default.maxReloadSpeed[1];
	if (upgLevel > 1)
		Resolved_maxReloadSpeed = Val_maxReloadSpeed_1;
	else
		Resolved_maxReloadSpeed = Val_maxReloadSpeed_0;
	if (H != None && H.Values[17] != 0.0f)
		Val_minHealth = H.Values[17];
	else
		Val_minHealth = default.minHealth;
	if (OwnerPawn != None && OwnerPawn.Health < Val_minHealth)
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Resolved_maxReloadSpeed * (1.0f - OwnerPawn.Health / Val_minHealth));
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Pressure"
}
