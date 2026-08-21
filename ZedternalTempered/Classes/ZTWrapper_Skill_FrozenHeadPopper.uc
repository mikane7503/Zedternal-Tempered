// Wrapper for ZedternalReborn.WMUpgrade_Skill_FrozenHeadPopper
class ZTWrapper_Skill_FrozenHeadPopper extends WMUpgrade_Skill_FrozenHeadPopper config(ZedternalUnlimited);

var config float Cfg_MaxDamage;
var config float Cfg_Probability;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MaxDamage = 800.0f;
		default.Cfg_Probability = 0.2f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_maxDamage = 800.000000f;
		default.Cfg_Probability = 0.030000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local rotator Rot;
	local vector Loc;

	if (MyKFPM != None && DamageInstigator != None && HitZoneIdx == HZI_HEAD && FRand() < Fmin(default.Cfg_Probability, (float(DefaultDamage) / default.Cfg_MaxDamage)))
	{
		Rot = rotator(MyKFPM.Velocity);
		Loc = MyKFPM.Location;
		Loc.Z -= MyKFPM.GetCollisionHeight();
		Rot.Pitch = 0;
		if (upgLevel == 1)
			DamageInstigator.Spawn(class'ZedternalReborn.WMProj_FreezeExplosion', DamageInstigator, , Loc, Rot, , True);
		else
			DamageInstigator.Spawn(class'ZedternalReborn.WMProj_FreezeExplosion_Deluxe', DamageInstigator, , Loc, Rot, , True);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_FrozenHeadPopper"
}
