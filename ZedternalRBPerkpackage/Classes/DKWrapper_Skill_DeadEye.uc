// Wrapper for ZedternalReborn.WMUpgrade_Skill_DeadEye
class DKWrapper_Skill_DeadEye extends WMUpgrade_Skill_DeadEye
	config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

const SLOT_Bonus_0 = 3;
const SLOT_Bonus_1 = 4;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.1f;
		default.Cfg_Bonus[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[3] = default.Cfg_Bonus[0];
	H.Values[4] = default.Cfg_Bonus[1];
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (HitZoneIdx == HZI_HEAD && MyKFW != None && MyKFW.bUsingSights)
		InDamage += Round(float(DefaultDamage) * default.Cfg_Bonus[upgLevel - 1]);
}

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	local DKBalanceRepHelper H;
	local float Val_Bonus_0;
	local float Val_Bonus_1;
	local float Resolved_Bonus;

	H = class'DKBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[3] != 0.0f)
		Val_Bonus_0 = H.Values[3];
	else
		Val_Bonus_0 = default.Bonus[0];
	if (H != None && H.Values[4] != 0.0f)
		Val_Bonus_1 = H.Values[4];
	else
		Val_Bonus_1 = default.Bonus[1];
	if (upgLevel > 1)
		Resolved_Bonus = Val_Bonus_1;
	else
		Resolved_Bonus = Val_Bonus_0;
	if (KFW != None && KFW.bUsingSights)
		InRecoilModifier -= DefaultRecoilModifier * Resolved_Bonus;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_DeadEye"
}
