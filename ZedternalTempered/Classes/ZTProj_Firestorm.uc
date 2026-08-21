class ZTProj_Firestorm extends KFProj_MolotovGrenade hidedropdown;

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
		MyDamageType=class'KFDT_Fire_MolotovGrenade'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
	End Object

	Name="Default__ZTProj_Firestorm"
}