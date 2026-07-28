// Wrapper for ZedternalReborn.WMUpgrade_Skill_WhirlwindOfLead
class DKWrapper_Skill_WhirlwindOfLead extends WMUpgrade_Skill_WhirlwindOfLead
	config(ZedternalUnlimited);

var config array<float> Cfg_SpecialRate;
var config array<float> Cfg_FireRate;
var config int MODEVERSION;

const SLOT_FireRate_0 = 44;
const SLOT_FireRate_1 = 45;
const SLOT_SpecialRate_0 = 46;
const SLOT_SpecialRate_1 = 47;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SpecialRate[0] = 0.2f;
		default.Cfg_SpecialRate[1] = 0.4f;
		default.Cfg_FireRate[0] = 0.5f;
		default.Cfg_FireRate[1] = 0.9f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[44] = default.Cfg_FireRate[0];
	H.Values[45] = default.Cfg_FireRate[1];
	H.Values[46] = default.Cfg_SpecialRate[0];
	H.Values[47] = default.Cfg_SpecialRate[1];
}

static simulated function GetZedTimeModifier(out float InModifier, int upgLevel, KFWeapon KFW)
{
	local DKBalanceRepHelper H;
	local float Val_FireRate_0;
	local float Val_FireRate_1;
	local float Resolved_FireRate;
	local float Val_SpecialRate_0;
	local float Val_SpecialRate_1;
	local float Resolved_SpecialRate;
	local name StateName;

	H = class'DKBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[44] != 0.0f)
		Val_FireRate_0 = H.Values[44];
	else
		Val_FireRate_0 = default.FireRate[0];
	if (H != None && H.Values[45] != 0.0f)
		Val_FireRate_1 = H.Values[45];
	else
		Val_FireRate_1 = default.FireRate[1];
	if (upgLevel > 1)
		Resolved_FireRate = Val_FireRate_1;
	else
		Resolved_FireRate = Val_FireRate_0;
	if (H != None && H.Values[46] != 0.0f)
		Val_SpecialRate_0 = H.Values[46];
	else
		Val_SpecialRate_0 = default.SpecialRate[0];
	if (H != None && H.Values[47] != 0.0f)
		Val_SpecialRate_1 = H.Values[47];
	else
		Val_SpecialRate_1 = default.SpecialRate[1];
	if (upgLevel > 1)
		Resolved_SpecialRate = Val_SpecialRate_1;
	else
		Resolved_SpecialRate = Val_SpecialRate_0;
	if (KFW != None)
	{
		StateName = KFW.GetStateName();
		if (class'ZedternalReborn.WMWeaponStates'.static.IsWeaponAttackState(StateName))
		{
			if (KFWeap_MeleeBase(KFW) != None || KFW.default.MagazineCapacity[0] > 4)
				InModifier += Resolved_FireRate;
			else
				InModifier += Resolved_SpecialRate;
		}
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_WhirlwindOfLead"
}
