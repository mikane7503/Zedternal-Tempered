// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_SuddenBloating
class DKWrapper_Skill_SuddenBloating extends ZRUpgrade_Skill_SuddenBloating
	config(ZedternalUnlimited);

var config float Cfg_MaxDamage;
var config float Cfg_Probability;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MaxDamage = 800.0f;
		default.Cfg_Probability = 0.05f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local rotator Rot;
	local vector Loc;

	if (MyKFPM != None && DamageInstigator != None && FRand() < Fmin(default.Cfg_Probability, (float(DefaultDamage) / default.Cfg_MaxDamage)))
	{
		Rot = rotator(MyKFPM.Velocity);
		Loc = MyKFPM.Location;
		Loc.Z -= MyKFPM.GetCollisionHeight();
		Rot.Pitch = 0;
		if (upgLevel == 1)
			DamageInstigator.Spawn(class'ZedternalRBPerkpackage.DKProj_ToxicGas', DamageInstigator, , Loc, Rot, , True);
		else
			DamageInstigator.Spawn(class'ZedternalRBPerkpackage.DKProj_ToxicGas_Deluxe', DamageInstigator, , Loc, Rot, , True);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_SuddenBloating"
}
