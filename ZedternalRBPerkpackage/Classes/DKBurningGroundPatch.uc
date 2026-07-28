class DKBurningGroundPatch extends KFProj_MolotovGrenade
	hidedropdown;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (Other.bBlockActors)
	{
		if (KFDestructibleActor(Other) != None && KFDestructibleActor(Other).ReplicationMode == RT_ClientSide)
		{
			return;
		}

		Explode(Location, HitNormal);
	}
}

defaultproperties
{
	bWarnAIWhenFired=False
	FuseTime=0.25f
	Speed=0.0f
	TerminalVelocity=0.0f
	TossZ=0.0f

	NumResidualFlames=3

	AssociatedPerkClass=class'ZedternalReborn.WMPerk'

	Begin Object Name=ExploTemplate0
		Damage=30.0f
		DamageRadius=200.0f
		MyDamageType=class'ZedternalRBPerkpackage.DKDT_ForgeWarden_BurningGround'
		ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'

		ExplosionEffects=KFImpactEffectInfo'WEP_Flamethrower_ARCH.GroundFire_Impacts'
		ExplosionSound=AkEvent'WW_WEP_Flare_Gun.Play_WEP_Flare_Gun_Explode'

		CamShakeInnerRadius=5.0f
		CamShakeOuterRadius=8.0f
	End Object

	Name="Default__DKBurningGroundPatch"
}
