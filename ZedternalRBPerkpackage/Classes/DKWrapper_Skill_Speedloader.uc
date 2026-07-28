// Wrapper for ZedternalReborn.WMUpgrade_Skill_Speedloader
class DKWrapper_Skill_Speedloader extends WMUpgrade_Skill_Speedloader
	config(ZedternalUnlimited);

var config array<float> Cfg_MinReloadSpeed;
var config array<float> Cfg_MaxReloadSpeed;
var config int MODEVERSION;

const SLOT_MaxReloadSpeed_0 = 32;
const SLOT_MaxReloadSpeed_1 = 33;
const SLOT_MinReloadSpeed_0 = 34;
const SLOT_MinReloadSpeed_1 = 35;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MinReloadSpeed[0] = 0.1f;
		default.Cfg_MinReloadSpeed[1] = 0.25f;
		default.Cfg_MaxReloadSpeed[0] = 0.4f;
		default.Cfg_MaxReloadSpeed[1] = 0.75f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[32] = default.Cfg_MaxReloadSpeed[0];
	H.Values[33] = default.Cfg_MaxReloadSpeed[1];
	H.Values[34] = default.Cfg_MinReloadSpeed[0];
	H.Values[35] = default.Cfg_MinReloadSpeed[1];
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_MaxReloadSpeed_0;
	local float Val_MaxReloadSpeed_1;
	local float Resolved_MaxReloadSpeed;
	local float Val_MinReloadSpeed_0;
	local float Val_MinReloadSpeed_1;
	local float Resolved_MinReloadSpeed;
	local float Load;

	H = class'DKBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[32] != 0.0f)
		Val_MaxReloadSpeed_0 = H.Values[32];
	else
		Val_MaxReloadSpeed_0 = default.MaxReloadSpeed[0];
	if (H != None && H.Values[33] != 0.0f)
		Val_MaxReloadSpeed_1 = H.Values[33];
	else
		Val_MaxReloadSpeed_1 = default.MaxReloadSpeed[1];
	if (upgLevel > 1)
		Resolved_MaxReloadSpeed = Val_MaxReloadSpeed_1;
	else
		Resolved_MaxReloadSpeed = Val_MaxReloadSpeed_0;
	if (H != None && H.Values[34] != 0.0f)
		Val_MinReloadSpeed_0 = H.Values[34];
	else
		Val_MinReloadSpeed_0 = default.MinReloadSpeed[0];
	if (H != None && H.Values[35] != 0.0f)
		Val_MinReloadSpeed_1 = H.Values[35];
	else
		Val_MinReloadSpeed_1 = default.MinReloadSpeed[1];
	if (upgLevel > 1)
		Resolved_MinReloadSpeed = Val_MinReloadSpeed_1;
	else
		Resolved_MinReloadSpeed = Val_MinReloadSpeed_0;
	if (KFW != None)
	{
		Load = FMax(float(KFW.AmmoCount[0]) / float(KFW.MagazineCapacity[0]), 0.0f);
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Load * Resolved_MaxReloadSpeed + Resolved_MinReloadSpeed);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Speedloader"
}
