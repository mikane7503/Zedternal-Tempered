// Wrapper for ZedternalReborn.WMUpgrade_Skill_Massacre
class ZTWrapper_Skill_Massacre extends WMUpgrade_Skill_Massacre config(ZedternalUnlimited);

var config array<float> Cfg_MeleeDamage;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MeleeDamage[0] = 0.2f;
		default.Cfg_MeleeDamage[1] = 0.5f;
		default.Cfg_Damage[0] = 0.05f;
		default.Cfg_Damage[1] = 0.15f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MeleeDamage.Length = 2;
		default.Cfg_MeleeDamage[0] = 0.200000f;
		default.Cfg_MeleeDamage[1] = 0.500000f;
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.050000f;
		default.Cfg_Damage[1] = 0.150000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && static.IsMeleeDamageType(DamageType))
		InDamage += int(float(DefaultDamage) * default.Cfg_MeleeDamage[upgLevel - 1]);
	else
		InDamage += int(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Massacre"
}
