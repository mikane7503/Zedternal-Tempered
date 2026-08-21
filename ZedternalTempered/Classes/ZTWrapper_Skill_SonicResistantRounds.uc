// Wrapper for ZedternalReborn.WMUpgrade_Skill_SonicResistantRounds
class ZTWrapper_Skill_SonicResistantRounds extends WMUpgrade_Skill_SonicResistantRounds config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.4f;
		default.Cfg_Damage[1] = 1.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.250000f;
		default.Cfg_Damage[1] = 0.400000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Sonic'))
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_SonicResistantRounds"
}
