// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_AddedVoltage
class DKWrapper_Skill_AddedVoltage extends ZRUpgrade_Skill_AddedVoltage
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.50f;
		default.Cfg_Damage[1] = 1.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_EMP') || ClassIsChildOf(DamageType, class'ZRDT_ChargedRounds_DoT'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1] * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_AddedVoltage"
}
