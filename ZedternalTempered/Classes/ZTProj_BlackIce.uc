class ZTProj_BlackIce extends KFProj_FreezeThrower_GroundIce hidedropdown;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
}

defaultproperties
{
	AssociatedPerkClass=Class'ZedternalReborn.WMPerk'

	PostExplosionLifetime=5.0

	Begin Object Name=ExploTemplate0
		Damage=0.1f
		DamageRadius=100.0f
		MyDamageType=Class'ZedternalTempered.ZTDT_BlackIce'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__ZRProj_BlackIce"
}
