// Wrapper for ZedternalReborn.WMUpgrade_Skill_MadBomber
class ZTWrapper_Skill_MadBomber extends WMUpgrade_Skill_MadBomber config(ZedternalUnlimited);

var config array<float> Cfg_Resistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Resistance[0] = 0.3f;
		default.Cfg_Resistance[1] = 0.7f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Resistance.Length = 2;
		default.Cfg_Resistance[0] = 0.100000f;
		default.Cfg_Resistance[1] = 0.200000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive') && InstigatedBy != None && OwnerPawn != None && InstigatedBy == OwnerPawn.Controller)
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Resistance[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_MadBomber"
}
