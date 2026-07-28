// Wrapper for ZedternalReborn.WMUpgrade_Skill_HeatWaves
class DKWrapper_Skill_HeatWaves extends WMUpgrade_Skill_HeatWaves
	config(ZedternalUnlimited);

var config float Cfg_Stumble;
var config array<float> Cfg_Damage;
var config array<int> Cfg_RadiusSQ;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Stumble = 1.5f;
		default.Cfg_Damage[0] = 0.8f;
		default.Cfg_Damage[1] = 2.0f;
		default.Cfg_RadiusSQ[0] = 90000;
		default.Cfg_RadiusSQ[1] = 360000;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Fire_Ground'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower, int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
	if (OwnerPawn != None && KFP != None && VSizeSQ(OwnerPawn.Location - KFP.Location) <= default.Cfg_RadiusSQ[upgLevel - 1])
		InStumblePower += DefaultStumblePower * default.Cfg_Stumble;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_HeatWaves"
}
