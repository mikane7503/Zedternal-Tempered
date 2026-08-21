// Wrapper for ZedternalReborn.WMUpgrade_Skill_Concentration
class ZTWrapper_Skill_Concentration extends WMUpgrade_Skill_Concentration config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.3f;
		default.Cfg_Damage[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.300000f;
		default.Cfg_Damage[1] = 0.500000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageInstigator != None && DamageInstigator.WorldInfo.TimeDilation < 1)
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Concentration"
}
