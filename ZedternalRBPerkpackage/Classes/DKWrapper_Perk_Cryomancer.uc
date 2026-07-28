// Wrapper for HowdyZTRExt.ZRUpgrade_Perk_Cryomancer
class DKWrapper_Perk_Cryomancer extends ZRUpgrade_Perk_Cryomancer
	config(ZedternalUnlimited);

var config float Cfg_Speed;
var config float Cfg_Damage;
var config float Cfg_Penetration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Speed = 0.15f;
		default.Cfg_Damage = 0.05f;
		default.Cfg_Penetration = 0.15f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Freeze'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static simulated function GetCrouchSpeedModifier(out float InSpeed, float DefaultSpeed, int upgLevel)
{
	local float Fb_Speed;

	Fb_Speed = default.Cfg_Speed;
	if (Fb_Speed == 0)
		Fb_Speed = default.Speed;
	InSpeed += Fb_Speed * upgLevel;
}

static simulated function ModifyPenetrationPassive(out float penetrationFactor, int upgLevel)
{
	local float Fb_Penetration;

	Fb_Penetration = default.Cfg_Penetration;
	if (Fb_Penetration == 0)
		Fb_Penetration = default.Penetration;
	penetrationFactor += Fb_Penetration * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Cryomancer"
}
