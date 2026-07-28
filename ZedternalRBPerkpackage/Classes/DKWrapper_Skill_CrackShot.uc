// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_CrackShot
class DKWrapper_Skill_CrackShot extends ZRUpgrade_Skill_CrackShot
	config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.1f;
		default.Cfg_Bonus[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (HitZoneIdx == HZI_HEAD && MyKFW != None)
		InDamage += Round(float(DefaultDamage) * default.Cfg_Bonus[upgLevel - 1]);
}

static simulated function GetIronSightSpeedModifier(out float InSpeed, float DefaultSpeed, int upgLevel)
{
	local float Fb_Bonus;

	if (default.Cfg_Bonus.Length > 0 && default.Cfg_Bonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Bonus.Length > 1)
			Fb_Bonus = default.Cfg_Bonus[1];
		else
			Fb_Bonus = default.Cfg_Bonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.Bonus.Length > 1)
			Fb_Bonus = default.Bonus[1];
		else
			Fb_Bonus = default.Bonus[0];
	}
	InSpeed -= DefaultSpeed * Fb_Bonus;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_CrackShot"
}
