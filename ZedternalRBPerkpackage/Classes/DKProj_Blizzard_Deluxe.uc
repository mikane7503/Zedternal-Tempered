class DKProj_Blizzard_Deluxe extends KFProj_FreezeGrenade
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
		Damage=3.00f
		DamageRadius=2000.0f
		MyDamageType=Class'ZedternalRBPerkpackage.DKDT_Blizzard_Deluxe'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__DKProj_Blizzard_Deluxe"
}