// Hand-written wrapper for HowdyZTRExt.ZRUpgrade_Skill_BileBomb
// Overrides ModifyDamageGiven to spawn configurable DK projectiles
class DKWrapper_Skill_BileBomb extends ZRUpgrade_Skill_BileBomb
	config(ZedternalUnlimited);

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local rotator Rot;
	local vector Loc;

	if (MyKFPM != None && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0 && DamageInstigator != None && DamageInstigator.Pawn != None && (ClassIsChildOf(DamageType, class'KFDT_Toxic')))
	{
		Rot = rotator(MyKFPM.Velocity);
		Loc = MyKFPM.Location;
		Loc.Z -= MyKFPM.GetCollisionHeight();
		Rot.Pitch = 0;
		if (upgLevel == 1)
			DamageInstigator.Spawn(class'ZedternalRBPerkpackage.DKProj_BileBomb', DamageInstigator, , Loc, Rot, , True);
		else
			DamageInstigator.Spawn(class'ZedternalRBPerkpackage.DKProj_BileBomb_Deluxe', DamageInstigator, , Loc, Rot, , True);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_BileBomb"
}
