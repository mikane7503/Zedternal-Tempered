// Wrapper for ZedternalReborn.WMUpgrade_Skill_Pyromaniac
class ZTWrapper_Skill_Pyromaniac extends WMUpgrade_Skill_Pyromaniac config(ZedternalUnlimited);

var config array<float> Cfg_RateOfFire;
var config int MODEVERSION;

const SLOT_RateOfFire_0 = 18;
const SLOT_RateOfFire_1 = 19;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_RateOfFire[0] = 0.2f;
		default.Cfg_RateOfFire[1] = 0.4f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_RateOfFire.Length = 2;
		default.Cfg_RateOfFire[0] = 0.200000f;
		default.Cfg_RateOfFire[1] = 0.400000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[18] = default.Cfg_RateOfFire[0];
	H.Values[19] = default.Cfg_RateOfFire[1];
}

static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
	local ZTBalanceRepHelper H;
	local float Val_RateOfFire_0;
	local float Val_RateOfFire_1;
	local float Resolved_RateOfFire;
	local WMUpgrade_Skill_Pyromaniac_Helper UPG;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[18] != 0.0f)
		Val_RateOfFire_0 = H.Values[18];
	else
		Val_RateOfFire_0 = default.RateOfFire[0];
	if (H != None && H.Values[19] != 0.0f)
		Val_RateOfFire_1 = H.Values[19];
	else
		Val_RateOfFire_1 = default.RateOfFire[1];
	if (upgLevel > 1)
		Resolved_RateOfFire = Val_RateOfFire_1;
	else
		Resolved_RateOfFire = Val_RateOfFire_0;
	if (KFW != None)
	{
		UPG = GetHelper(KFPawn(KFW.Owner), upgLevel);
		if (UPG != None && UPG.bEnable)
			InDuration = DefaultDuration / (DefaultDuration / InDuration + Resolved_RateOfFire);
	}
}

static simulated function ModifyRateOfFire(out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW)
{
	local ZTBalanceRepHelper H;
	local float Val_RateOfFire_0;
	local float Val_RateOfFire_1;
	local float Resolved_RateOfFire;
	local WMUpgrade_Skill_Pyromaniac_Helper UPG;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[18] != 0.0f)
		Val_RateOfFire_0 = H.Values[18];
	else
		Val_RateOfFire_0 = default.RateOfFire[0];
	if (H != None && H.Values[19] != 0.0f)
		Val_RateOfFire_1 = H.Values[19];
	else
		Val_RateOfFire_1 = default.RateOfFire[1];
	if (upgLevel > 1)
		Resolved_RateOfFire = Val_RateOfFire_1;
	else
		Resolved_RateOfFire = Val_RateOfFire_0;
	if (KFW != None)
	{
		UPG = GetHelper(KFPawn(KFW.Owner), upgLevel);
		if (UPG != None && UPG.bEnable)
			InRate = DefaultRate / (DefaultRate / InRate + Resolved_RateOfFire);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Pyromaniac"
}
