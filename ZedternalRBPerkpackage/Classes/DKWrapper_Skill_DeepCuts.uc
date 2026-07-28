// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_DeepCuts
class DKWrapper_Skill_DeepCuts extends ZRUpgrade_Skill_DeepCuts
	config(ZedternalUnlimited);

var config array<float> Cfg_damageFactor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_damageFactor[0] = 0.2f;
		default.Cfg_damageFactor[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && DamageType != default.ZRDT && DamageInstigator != None && MyKFPM != None && static.IsMeleeDamageType(DamageType))
	{
		//add poison effects on zed
		MyKFPM.ApplyDamageOverTime(int(float(DefaultDamage) * default.Cfg_damageFactor[upgLevel - 1]), DamageInstigator, default.ZRDT);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_DeepCuts"
}
