// Wrapper for ZedternalReborn.WMUpgrade_Skill_Ranger
class DKWrapper_Skill_Ranger extends WMUpgrade_Skill_Ranger
	config(ZedternalUnlimited);

var config array<float> Cfg_Stun;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Stun[0] = 0.5f;
		default.Cfg_Stun[1] = 1.25f;
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyStunPower(out float InStunPower, float DefaultStunPower, int upgLevel, optional class<DamageType> DamageType, optional byte HitZoneIdx)
{
	if (HitZoneIdx == HZI_HEAD)
		InStunPower += DefaultStunPower * default.Cfg_Stun[upgLevel - 1];
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (HitZoneIdx == HZI_HEAD)
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Ranger"
}
