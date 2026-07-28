// Wrapper for ZedternalReborn.WMUpgrade_Skill_ImpactRounds
class DKWrapper_Skill_ImpactRounds extends WMUpgrade_Skill_ImpactRounds
	config(ZedternalUnlimited);

var config array<float> Cfg_Stumble;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Stumble[0] = 0.2f;
		default.Cfg_Stumble[1] = 0.5f;
		default.Cfg_Damage[0] = 0.1f;
		default.Cfg_Damage[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Ballistic'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

static function ModifyStumblePowerPassive(out float stumblePowerFactor, int upgLevel)
{
	stumblePowerFactor += default.Cfg_Stumble[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ImpactRounds"
}
