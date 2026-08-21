// Wrapper for ZedternalReborn.WMUpgrade_Skill_RiotShield
class ZTWrapper_Skill_RiotShield extends WMUpgrade_Skill_RiotShield config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config array<float> Cfg_OtherDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.5f;
		default.Cfg_Damage[1] = 0.9f;
		default.Cfg_OtherDamage[0] = 0.05f;
		default.Cfg_OtherDamage[1] = 0.1f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.250000f;
		default.Cfg_Damage[1] = 0.400000f;
		default.Cfg_OtherDamage.Length = 2;
		default.Cfg_OtherDamage[0] = 0.050000f;
		default.Cfg_OtherDamage[1] = 0.100000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(Damagetype, class'KFDT_Ballistic'))
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
	else
		InDamage -= Round(float(DefaultDamage) * default.Cfg_OtherDamage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_RiotShield"
}
