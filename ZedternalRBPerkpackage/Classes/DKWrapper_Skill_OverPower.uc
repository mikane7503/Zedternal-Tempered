// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_OverPower
class DKWrapper_Skill_OverPower extends ZRUpgrade_Skill_OverPower
	config(ZedternalUnlimited);

var config array<float> Cfg_knockdownPowerFactor;
var config array<float> Cfg_stumblePowerFactor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_knockdownPowerFactor[0] = 0.40f;
		default.Cfg_knockdownPowerFactor[1] = 0.80f;
		default.Cfg_stumblePowerFactor[0] = 0.75f;
		default.Cfg_stumblePowerFactor[1] = 1.00f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && static.IsMeleeDamageType(DamageType))
		InDamage += float(DefaultDamage) * default.Cfg_stumblePowerFactor[upgLevel - 1];
		InDamage += float(DefaultDamage) * default.Cfg_knockdownPowerFactor[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_OverPower"
}
