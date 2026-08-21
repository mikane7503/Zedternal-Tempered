// Wrapper for ZedternalReborn.WMUpgrade_Skill_Watcher
class ZTWrapper_Skill_Watcher extends WMUpgrade_Skill_Watcher config(ZedternalUnlimited);

var config float Cfg_CriticalHealth;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_CriticalHealth = 0.25f;
		default.Cfg_Damage[0] = 0.25f;
		default.Cfg_Damage[1] = 0.6f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_CriticalHealth = 0.250000f;
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.250000f;
		default.Cfg_Damage[1] = 0.600000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM != None && MyKFPM.Health <= int(float(MyKFPM.HealthMax) * default.Cfg_CriticalHealth))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Watcher"
}
