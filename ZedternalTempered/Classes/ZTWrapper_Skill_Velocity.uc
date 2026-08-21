// Wrapper for ZedternalReborn.WMUpgrade_Skill_Velocity
class ZTWrapper_Skill_Velocity extends WMUpgrade_Skill_Velocity config(ZedternalUnlimited);

var config float Cfg_MaxRadius;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MaxRadius = 50000000.0f;
		default.Cfg_Damage[0] = 0.25f;
		default.Cfg_Damage[1] = 0.6f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MaxRadius = 50000000.000000f;
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
	local float RangeFactor;

	if (MyKFPM != None && DamageInstigator != None && DamageInstigator.Pawn != None)
	{
		RangeFactor = FMin(1.0f, VSizeSQ(DamageInstigator.Pawn.Location - MyKFPM.Location) / default.Cfg_MaxRadius);
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1] * RangeFactor);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Velocity"
}
