// Wrapper for ZedternalReborn.WMUpgrade_Skill_Emergency
class ZTWrapper_Skill_Emergency extends WMUpgrade_Skill_Emergency config(ZedternalUnlimited);

var config float Cfg_MinHealthInv;
var config array<float> Cfg_MaxSpeed;
var config int Cfg_MinHealth;
var config int MODEVERSION;

const SLOT_MaxSpeed_0 = 5;
const SLOT_MaxSpeed_1 = 6;
const SLOT_MinHealth = 7;
const SLOT_MinHealthInv = 8;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MinHealthInv = 0.02f;
		default.Cfg_MaxSpeed[0] = 0.3f;
		default.Cfg_MaxSpeed[1] = 0.75f;
		default.Cfg_MinHealth = 50;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MinHealthInv = 0.020000f;
		default.Cfg_MaxSpeed.Length = 2;
		default.Cfg_MaxSpeed[0] = 0.300000f;
		default.Cfg_MaxSpeed[1] = 0.750000f;
		default.Cfg_MinHealth = 50;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[5] = default.Cfg_MaxSpeed[0];
	H.Values[6] = default.Cfg_MaxSpeed[1];
	H.Values[7] = default.Cfg_MinHealth;
	H.Values[8] = default.Cfg_MinHealthInv;
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTBalanceRepHelper H;
	local float Val_MaxSpeed_0;
	local float Val_MaxSpeed_1;
	local float Resolved_MaxSpeed;
	local int Val_MinHealth;
	local float Val_MinHealthInv;

	H = class'ZTBalanceRepHelper'.static.GetHelper(OwnerPawn);
	if (H != None && H.Values[5] != 0.0f)
		Val_MaxSpeed_0 = H.Values[5];
	else
		Val_MaxSpeed_0 = default.MaxSpeed[0];
	if (H != None && H.Values[6] != 0.0f)
		Val_MaxSpeed_1 = H.Values[6];
	else
		Val_MaxSpeed_1 = default.MaxSpeed[1];
	if (upgLevel > 1)
		Resolved_MaxSpeed = Val_MaxSpeed_1;
	else
		Resolved_MaxSpeed = Val_MaxSpeed_0;
	if (H != None && H.Values[7] != 0.0f)
		Val_MinHealth = H.Values[7];
	else
		Val_MinHealth = default.MinHealth;
	if (H != None && H.Values[8] != 0.0f)
		Val_MinHealthInv = H.Values[8];
	else
		Val_MinHealthInv = default.MinHealthInv;
	if (OwnerPawn != None && OwnerPawn.Health < Val_MinHealth)
		InSpeed += DefaultSpeed * Resolved_MaxSpeed * float(Val_MinHealth - OwnerPawn.Health) * Val_MinHealthInv;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Emergency"
}
