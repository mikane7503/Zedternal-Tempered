// Wrapper for ZedternalReborn.WMUpgrade_Skill_FrontLine
class ZTWrapper_Skill_FrontLine extends WMUpgrade_Skill_FrontLine config(ZedternalUnlimited);

var config array<float> Cfg_OtherResistance;
var config array<float> Cfg_SelfExplosiveResistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_OtherResistance[0] = 0.05f;
		default.Cfg_OtherResistance[1] = 0.1f;
		default.Cfg_SelfExplosiveResistance[0] = 0.35f;
		default.Cfg_SelfExplosiveResistance[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_OtherResistance.Length = 2;
		default.Cfg_OtherResistance[0] = 0.020000f;
		default.Cfg_OtherResistance[1] = 0.040000f;
		default.Cfg_SelfExplosiveResistance.Length = 2;
		default.Cfg_SelfExplosiveResistance[0] = 0.100000f;
		default.Cfg_SelfExplosiveResistance[1] = 0.200000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive') && KFPlayerController(InstigatedBy) != None)
		InDamage -= DefaultDamage * default.Cfg_SelfExplosiveResistance[upgLevel - 1];
	else
		InDamage -= DefaultDamage * default.Cfg_OtherResistance[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_FrontLine"
}
