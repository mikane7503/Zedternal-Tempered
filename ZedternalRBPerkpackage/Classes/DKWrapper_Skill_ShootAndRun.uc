// Wrapper for ZedternalReborn.WMUpgrade_Skill_ShootAndRun
class DKWrapper_Skill_ShootAndRun extends WMUpgrade_Skill_ShootAndRun
	config(ZedternalUnlimited);

var config array<float> Cfg_MaxMoveSpeedBonus;
var config array<float> Cfg_MaxReloadSpeedBonus;
var config int MODEVERSION;

const SLOT_MaxMoveSpeedBonus_0 = 22;
const SLOT_MaxMoveSpeedBonus_1 = 23;
const SLOT_MaxReloadSpeedBonus_0 = 24;
const SLOT_MaxReloadSpeedBonus_1 = 25;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MaxMoveSpeedBonus[0] = 0.2f;
		default.Cfg_MaxMoveSpeedBonus[1] = 0.5f;
		default.Cfg_MaxReloadSpeedBonus[0] = 0.5f;
		default.Cfg_MaxReloadSpeedBonus[1] = 1.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[22] = default.Cfg_MaxMoveSpeedBonus[0];
	H.Values[23] = default.Cfg_MaxMoveSpeedBonus[1];
	H.Values[24] = default.Cfg_MaxReloadSpeedBonus[0];
	H.Values[25] = default.Cfg_MaxReloadSpeedBonus[1];
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_MaxReloadSpeedBonus_0;
	local float Val_MaxReloadSpeedBonus_1;
	local float Resolved_MaxReloadSpeedBonus;
	local WMUpgrade_Skill_ShootAndRun_Helper UPG;

	H = class'DKBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[24] != 0.0f)
		Val_MaxReloadSpeedBonus_0 = H.Values[24];
	else
		Val_MaxReloadSpeedBonus_0 = default.MaxReloadSpeedBonus[0];
	if (H != None && H.Values[25] != 0.0f)
		Val_MaxReloadSpeedBonus_1 = H.Values[25];
	else
		Val_MaxReloadSpeedBonus_1 = default.MaxReloadSpeedBonus[1];
	if (upgLevel > 1)
		Resolved_MaxReloadSpeedBonus = Val_MaxReloadSpeedBonus_1;
	else
		Resolved_MaxReloadSpeedBonus = Val_MaxReloadSpeedBonus_0;
	UPG = GetHelper(OwnerPawn);
	if (UPG != None && UPG.KilledZeds > 0)
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Resolved_MaxReloadSpeedBonus * UPG.GetKillPercentage());
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_MaxMoveSpeedBonus_0;
	local float Val_MaxMoveSpeedBonus_1;
	local float Resolved_MaxMoveSpeedBonus;
	local WMUpgrade_Skill_ShootAndRun_Helper UPG;

	H = class'DKBalanceRepHelper'.static.GetHelper(OwnerPawn);
	if (H != None && H.Values[22] != 0.0f)
		Val_MaxMoveSpeedBonus_0 = H.Values[22];
	else
		Val_MaxMoveSpeedBonus_0 = default.MaxMoveSpeedBonus[0];
	if (H != None && H.Values[23] != 0.0f)
		Val_MaxMoveSpeedBonus_1 = H.Values[23];
	else
		Val_MaxMoveSpeedBonus_1 = default.MaxMoveSpeedBonus[1];
	if (upgLevel > 1)
		Resolved_MaxMoveSpeedBonus = Val_MaxMoveSpeedBonus_1;
	else
		Resolved_MaxMoveSpeedBonus = Val_MaxMoveSpeedBonus_0;
	UPG = GetHelper(OwnerPawn);
	if (UPG != None && UPG.KilledZeds > 0)
		InSpeed += DefaultSpeed * Resolved_MaxMoveSpeedBonus * UPG.GetKillPercentage();
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ShootAndRun"
}
