// Wrapper for ZedternalReborn.WMUpgrade_Skill_Resistance
class ZTWrapper_Skill_Resistance extends WMUpgrade_Skill_Resistance config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.25f;
		default.Cfg_Damage[1] = 0.6f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.100000f;
		default.Cfg_Damage[1] = 0.200000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(Damagetype, class'KFDT_Toxic') || ClassIsChildOf(Damagetype, class'KFDT_Sonic') || ClassIsChildOf(Damagetype, class'KFDT_Fire')))
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Resistance"
}
