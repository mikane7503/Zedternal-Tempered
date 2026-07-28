class DKProj_Blizzard extends KFProj_FreezeGrenade
	hidedropdown;

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
		Damage=1.50f
		DamageRadius=500.0f
		MyDamageType=Class'ZedternalRBPerkpackage.DKDT_Blizzard'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__DKProj_Blizzard"
}