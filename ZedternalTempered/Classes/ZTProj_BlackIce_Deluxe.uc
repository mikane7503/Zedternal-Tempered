class ZTProj_BlackIce_Deluxe extends KFProj_FreezeThrower_GroundIce hidedropdown;

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
		DamageRadius=200.0f
		MyDamageType=Class'ZedternalTempered.ZTDT_BlackIce_Deluxe'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__ZRProj_BlackIce_Deluxe"
}
