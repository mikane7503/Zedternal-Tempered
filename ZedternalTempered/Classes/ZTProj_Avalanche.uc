class ZTProj_Avalanche extends KFProj_FreezeGrenade hidedropdown;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	ExplodeTimer();
}

defaultproperties
{
	AssociatedPerkClass=Class'ZedternalReborn.WMPerk'
	FuseTime=0.05f

	Begin Object Name=ExploTemplate0
		Damage=0.10f
		DamageRadius=100.0f
		MyDamageType=Class'ZedternalTempered.ZTDT_Avalanche'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__ZTProj_Avalanche"
}