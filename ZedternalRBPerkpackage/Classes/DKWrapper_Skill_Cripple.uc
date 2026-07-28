// Wrapper for ZedternalReborn.WMUpgrade_Skill_Cripple
class DKWrapper_Skill_Cripple extends WMUpgrade_Skill_Cripple
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config float Cfg_Snare;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.1f;
		default.Cfg_Damage[1] = 0.25f;
		default.Cfg_Snare = 10.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifySnarePowerPassive(out float snarePowerFactor, int upgLevel)
{
	snarePowerFactor += default.Cfg_Snare;
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Cripple"
}
