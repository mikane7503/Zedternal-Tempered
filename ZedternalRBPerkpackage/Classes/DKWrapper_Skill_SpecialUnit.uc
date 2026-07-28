// Wrapper for ZedternalReborn.WMUpgrade_Skill_SpecialUnit
class DKWrapper_Skill_SpecialUnit extends WMUpgrade_Skill_SpecialUnit
	config(ZedternalUnlimited);

var config array<float> Cfg_Speed;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

const SLOT_Speed_0 = 30;
const SLOT_Speed_1 = 31;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Speed[0] = 0.1f;
		default.Cfg_Speed[1] = 0.2f;
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[30] = default.Cfg_Speed[0];
	H.Values[31] = default.Cfg_Speed[1];
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageInstigator != None && WMPawn_Human(DamageInstigator.Pawn) != None && WMPawn_Human(DamageInstigator.Pawn).ZedternalArmor > 0)
		InDamage += DefaultDamage * default.Cfg_Damage[upgLevel - 1];
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_Speed_0;
	local float Val_Speed_1;
	local float Resolved_Speed;

	H = class'DKBalanceRepHelper'.static.GetHelper(OwnerPawn);
	if (H != None && H.Values[30] != 0.0f)
		Val_Speed_0 = H.Values[30];
	else
		Val_Speed_0 = default.Speed[0];
	if (H != None && H.Values[31] != 0.0f)
		Val_Speed_1 = H.Values[31];
	else
		Val_Speed_1 = default.Speed[1];
	if (upgLevel > 1)
		Resolved_Speed = Val_Speed_1;
	else
		Resolved_Speed = Val_Speed_0;
	if (WMPawn_Human(OwnerPawn) != None && WMPawn_Human(OwnerPawn).ZedternalArmor <= 0)
		InSpeed += DefaultSpeed * Resolved_Speed;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_SpecialUnit"
}
